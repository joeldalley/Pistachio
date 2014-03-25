use strict;
use warnings;

# Pistachio usage examples.
# @author Joel Dalley
# @version 2013/Dec/15

use File::Basename;
use File::DirWalk;
use File::Slurp;
use Pistachio;

# Assert existence of source code dirs.
my $moo_path = inc_having('Moo');       # from CPAN
my $pst_path = inc_having('Pistachio'); # from CPAN

# Examples to generate HTML for.
my %config = (
    Moo       => ["$moo_path/Moo", ["$moo_path/Moo.pm"]],
    Pistachio => ["$pst_path/Pistachio", ["$pst_path/Pistachio.pm"]]
    );

# Pistachio HTML handler, for snippet().
my $handler = Pistachio::html_handler('Perl5', 'Github');

# "Generated @" comment
my $generated = sprintf '<!-- Generated @ %s, using Pistachio version %s -->',
                        my $time = localtime, $Pistachio::VERSION;

# Generate HTML output files.
while (my ($name, $cfg) = each %config) {
    my ($path, $for_list) = @$cfg;

    # Pistachio-generated files.
    my @files;
    for my $path (file_list($path, @$for_list)) {
        my $ref = read_file $path, scalar_ref => 1 or die $!;
        my $snip = $handler->snippet($ref);
        my $out = to_html_output_path($name, $path);
        write_file $out, join "\n", $snip, $generated or die $!;
        push @files, $out;
    }

    # An index file for this example.
    my $a_spec = '<a style="font-size:16px;display:inline-block;margin-bottom:6px" href="%s">%s</a>';
    my $links = join '<br/>', map sprintf($a_spec, $_, $_), map basename($_), @files;

    my $html_spec = "<html><head><title>Pistachio Example :: %s</title></head>\n"
                  . "  <body style=\"font-family:Consolas,'Liberation Mono',Courier,monospace\">\n"
                  . "    <h1>Pistachio Example :: %s</h1>\n"
                  . "    <div style=\"white-space:pre\">%s</div>\n"
                  . "    %s\n"
                  . "  </body>\n"
                  . "</html>\n";
    my $index_html = sprintf $html_spec, $name, $name, $links, $generated;

    my $index_file = to_html_output_path($name, 'index');
    write_file $index_file, $index_html or die $!;
    push @files, $index_file;

    # Report.
    print "Example $name\n";
    print "\t$_\n" for @files;
    print "\n";
}

###############################################


# @param string A module name.
# @return string The @INC location for the given module.
sub inc_having { 
    my @dirs = grep -e "$_/$_[0].pm" && -d "$_/$_[0]", @INC;
    die "Cannot find $_[0] in \@INC" unless @dirs;
    shift @dirs;
}

# @param string $name A module name.
# @param string $path Path where named module is.
# @return string Path to Pistachio HTML output.
sub to_html_output_path {
    my ($name, $path) = @_;
 
    my $rel_dir = "../gh-pages/pistachio/$name";
    -e $rel_dir or mkdir $rel_dir or die $!;

    # flatten /path/to/files into path-to-files
    $path =~ s{^/}{}o;
    $path =~ s{/}{-}og;

    "$rel_dir/$path.html";
}

# @param string $path A directory to recursively read.
# @param array @list A partial list of files to add to.
# @return array A list of modules found within the dir, $path.
sub file_list {
    my ($path, @list) = (shift, @_);

    my $walker = File::DirWalk->new;
    $walker->onFile(sub {
        push @list, $_[0] if $_[0] =~ /\.pm$/o;
        return File::DirWalk::SUCCESS;
    });
    $walker->walk($path);

    @list;
}

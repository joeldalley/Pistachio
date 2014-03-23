use strict;
use warnings;

# Pistachio usage examples.
# @author Joel Dalley
# @version 2014/Mar/22

use File::Basename;
use File::DirWalk;
use File::Slurp;

use Pistachio;
use Pistachio::Token;
use Pistachio::Language;
use JBD::JSON 'std_parse';

# Define our own Pistachio::Language object by specifying
# the tokens, css and tranformer_rules subs; this way, we
# can use the existing Pistachio core to render our JSON, 
# even though Pistachio knows nothing about how to parse
# JSON, and gets all of its CSS styles from this object.
my $lang = Pistachio::Language->new('JSON',
    tokens => sub {
        my $tokens = std_parse 'json_text', $_[0];
        [map Pistachio::Token->new($_->type, $_->value), @$tokens];
    },
    css => sub {
        my %type_to_style = (
            JsonNum           => 'color:#008080',
            JsonNull          => 'color:#000',
            JsonBool          => 'color:#000',
            JsonString        => 'color:#D14',
            JsonColon         => 'color:#333',
            JsonComma         => 'color:#333',
            JsonSquareBracket => 'color:#333',
            JsonCurlyBrace    => 'color:#333',
            );
        $type_to_style{$_[0] || ''} || '';
    },
);

# Pistachio HTML handler, for snippet().
my $handler = Pistachio::html_handler($lang, 'Github');

# "Generated @" comment
my $generated = sprintf '<!-- Generated @ %s, using Pistachio version %s -->',
                        my $time = localtime, $Pistachio::VERSION;

# Generate HTML output files.
my @files;
my $name = 'JSON';
my @json_corpus = glob '/Users/joel/Code/JBD/JSON/bin/json_corpus/*.json';

for my $path (@json_corpus) {
    # Pistachio-generated files.
    my $ref = read_file $path, scalar_ref => 1, binmode => ':utf8'  or die $!;
    my $snip = $handler->snippet($ref);
    my $out = to_html_output_path($name, $path);
    write_file $out, {binmode => ':utf8'}, join "\n", $snip, $generated or die $!;
    push @files, $out;
}

# An index file.
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
write_file $index_file, {binmode => ':utf8'}, $index_html or die $!;
push @files, $index_file;

# Report.
print "$name\n";
print "\t$_\n" for @files;
print "\n";


###############################################


# @param string $rel_dir A directory name.
# @param string $path Path where JSON file is.
# @return string Path to Pistachio HTML output.
sub to_html_output_path {
    my ($rel_dir, $path) = @_;
 
    $rel_dir = "../gh-pages/pistachio/$rel_dir";
    -e $rel_dir or mkdir $rel_dir or die $!;

    # flatten /path/to/files into path-to-files
    $path =~ s{^/}{}o;
    $path =~ s{/}{-}og;

    "$rel_dir/$path.html";
}

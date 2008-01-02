use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/20fulldocs-multimarkdown.t";

my $docsdir = "$Bin/docs-markdown-todo";
my @files = get_files($docsdir);

plan tests => scalar(@files);

my $m = Text::MultiMarkdown->new(
    use_metadata => 0,
);

{
    local $TODO = 'These tests are known broken';
    run_tests($m, $docsdir, @files);
};

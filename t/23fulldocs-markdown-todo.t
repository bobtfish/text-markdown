use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/20fulldocs-multimarkdown.t";

my $docsdir = "$Bin/docs-markdown-todo";
my @files = get_files($docsdir);

plan tests => scalar(@files) + 1;

use_ok('Text::MultiMarkdown');

my $m = Text::MultiMarkdown->new(
    use_metadata => 0,
    heading_ids  => 0, # Remove MultiMarkdown behavior change in <hX> tags.
    img_ids      => 0, # Remove MultiMarkdown behavior change in <img> tags.
);

{
    local $TODO = 'I have many bugs!';
    run_tests($m, $docsdir, @files);
};
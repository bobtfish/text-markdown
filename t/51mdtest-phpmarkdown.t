use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/20fulldocs-multimarkdown.t";

tidy();

my $docsdir = "$Bin/PHP_Markdown-from-MDTest1.1.mdtest";
my @files = get_files($docsdir);

plan tests => scalar(@files) + 1;

use_ok('Text::Markdown');

my $m = Text::Markdown->new();

TODO: {
    local $TODO = 'Have not fixed a load of the bugs PHP markdown has yet.';
    run_tests($m, $docsdir, @files);
};

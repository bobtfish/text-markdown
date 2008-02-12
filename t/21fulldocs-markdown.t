use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

require "$Bin/20fulldocs-multimarkdown.t";

my $docsdir = "$Bin/docs-markdown";
my @files = get_files($docsdir);

plan tests => scalar(@files) + 1;

use_ok('Text::Markdown');

my $m = Text::Markdown->new();

run_tests($m, $docsdir, @files);

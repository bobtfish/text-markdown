use strict;
use warnings;
use Test::More tests => 3;
use Test::Differences;

use FindBin '$Bin';
use lib "$Bin/../lib";

use_ok 'Text::Markdown';
my $m = Text::Markdown->new();
my ($out, $expected);

$out = $m->markdown("foo\n\n\n");
eq_or_diff($out, "<p>foo</p>\n", "collapse multiple newlines at EOF into one");

$out = $m->markdown("foo");
eq_or_diff($out, "<p>foo</p>\n", "ensure newline before EOF");

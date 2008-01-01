use strict;
use warnings;
use Test::More tests => 3;

#1
use_ok( 'Text::MultiMarkdown');

my $m = Text::MultiMarkdown->new();
my $instr = qq{some metadata: here\n\nSome text};
my $outstr = qq{some metadata: here<br />\n\n<p>Some text</p>\n};
is( #2
    $m->markdown($instr) => $outstr, 
    'Normal element suffix as expected'
);

$outstr = qq{some metadata: here<br>\n\n<p>Some text</p>\n};
is( #3
    $m->markdown($instr, {empty_element_suffix => '>'}) => $outstr, 
    'HTML element suffix also as expected'
);

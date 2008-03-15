use strict;
use warnings;
use Test::More tests => 4;

use_ok('Text::MultiMarkdown');

my $m = Text::MultiMarkdown->new(
    disable_tables => 1,
    disable_footnotes => 1,
    disable_bibliography => 1,
);

my $instr = q{Here is some text containing a footnote.[^somesamplefootnote]
    
[^somesamplefootnote]: Here is the text of the footnote itself};
my $expstr = q{<p>Here is some text containing a footnote.[^somesamplefootnote]</p>

<p>[^somesamplefootnote]: Here is the text of the footnote itself</p>
};

is($m->markdown($instr) => $expstr, 'disable_footnotes works as expected');

$instr = q{This is a borrowed idea[p. 23][#Doe:1996].
    
[#Doe:1996]:	John Doe. *Some Book*. Blog Books, 1996.
};

# NOTE expstr doesn't have the footnote, as that syntax is original markdown's link syntax, so
#      it is now resolved to a link
$expstr = qq{<p>This is a borrowed idea[p. 23][#Doe:1996].</p>\n};

is($m->markdown($instr) => $expstr, 'disable_bibliography works as expected');

$instr = q{------------ | :-----------: | -----------: |
Content       |          Long Cell           ||
Content       |   Cell    |             Cell |};

$expstr = '<p>' . $instr . "</p>\n";

is( $m->markdown($instr) => $expstr, 'disable_tables works as expected');

use strict;
use warnings;
use Data::Dumper;
use Text::MultiMarkdown ();

my $m = Text::MultiMarkdown->new();

my $instr = q{
foo <i>bar</i> <iframe>some stuff in frame</iframe>
        <iframe>A code span</iframe>    
<iframe>
some stuff
</iframe>

<div style=">"/>

<h1 id="foobar">TEST</h1>

TESTHEAD
--------

};

#my $tokens = $m->_TokenizeHTML(q{<h1 id="foobar">heading</h1>});
#warn(Dumper($tokens));

my $t = $m->_TokenizeHTML(q{

a4a748a29119922cadf627d6fa11f1df





ce353b702315f5d55130188526375f88


});
#warn(Dumper($t));

#my $outstr = $m->_HashHTMLBlocks($instr);
my $outstr = $m->_TokenizeHTML($instr);

print Dumper($outstr);
print "*" x 80 . "\n";

#print $m->markdown($instr);

use strict;
use warnings;
use Text::MultiMarkdown ();

my $m = Text::MultiMarkdown->new();

my $instr = q{
foo <i>bar</i> <iframe>some stuff in frame</iframe>
        <iframe>A code span</iframe>    
<iframe>
some stuff
</iframe>
};

my $outstr = $m->_HashHTMLBlocks($instr);

print $outstr;

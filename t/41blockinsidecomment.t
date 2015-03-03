use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::Markdown');

{
    my $instr = <<EOM;
<!--
<div></div>
-->
EOM
    my $expstr = <<EOM;
<!--

<div></div>

-->
EOM

    is(Text::Markdown::markdown($instr) => $expstr, 'as expected');

};

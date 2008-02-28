use strict;
use warnings;
use Test::More tests => 2;

use_ok('Text::Markdown');

{
    local $TODO = 'Proposed syntax extension (on list) to deal with spaces in URLs by quoting them';
    
    my $instr = qq{![alternativer text]("pfad/und/eine lange/urlzu mbild.jpg" testtitle)\n};
    my $expstr = qq{<p><img src="pfad/und/eine%20lange/urlzu%20mbild.jpg" alt="alternativer text" title="testtitle" /></p>\n};

    is(Text::Markdown::markdown($instr) => $expstr, 'as expected');

};
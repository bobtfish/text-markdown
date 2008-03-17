use strict;
use warnings;
use Text::MultiMarkdown ();
use Test::More tests => 12;

# Test the _TokenizeHTML routine This takes a chunk of text/HTML and splits it on HTML tags which appear
# within tab_width -1 of the start of a line, making a number of tokens.
#
# It calls _TokenizeText 
#
# Outputs a list of tokens of the form ['text', $string] (as output by _TokenizeText), or ['tag', $fulltag, $FIXME]
# tokens.
#

my $m = Text::MultiMarkdown->new();

my $instr = qq{foobar};
my @exp = ( ['text', 'foobar'] );
my $out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, 'simplest case');

$instr = q{<div>foo</div>};
@exp = (
    ['tag',  '<div>', 'div',  0 ],
    ['text', 'foo'              ],
    ['tag',  '</div>', 'div', 0 ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<div>foo</div>');

$instr = qq{foobar\n<div>\nbaz\n</div>\nquux};
@exp = ( 
    ['text', 'foobar'           ], 
    ['text', "\n"               ], 
    ['tag',  '<div>',  'div', 0 ], 
    ['text', "\n"               ], 
    ['text', 'baz'              ], 
    ['text', "\n"               ], 
    ['tag',  '</div>', 'div', 0 ],
    ['text', "\n"               ], 
    ['text', 'quux'             ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, 'foobar\n<div>\nbaz\n</div>\nquux');

$instr = qq{foobar<div>baz\n</div>};
@exp = ( 
    ['text', 'foobar'           ], 
    ['tag',  '<div>',  'div', 0 ], 
    ['text', 'baz'              ], 
    ['text', "\n"               ], 
    ['tag',  '</div>', 'div', 0 ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, 'foobar<div>baz\n</div>');

$instr = qq{<h1 id="foobarbaz">Heading</h1>};
@exp = (
    ['tag',  '<h1 id="foobarbaz">', 'h1', 0 ],
    ['text', 'Heading'                      ],
    ['tag',  '</h1>', 'h1', 0               ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<h1 id="foobarbaz">Heading</h1>');

$instr = qq{<H1 ID='foobarbaz'>Heading</H1>};
@exp = (
    ['tag',  q{<H1 ID='foobarbaz'>}, 'h1', 0],
    ['text', 'Heading'                      ],
    ['tag',  '</H1>', 'h1', 0               ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, q{<H1 ID='foobarbaz'>Heading</H1>});

$instr = qq{<h1 id=foobarbaz >Heading</H1>};
@exp = (
    ['tag',  '<h1 id=foobarbaz >', 'h1', 0 ],
    ['text', 'Heading'                     ],
    ['tag',  '</H1>', 'h1', 0              ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<h1 id=foobarbaz>Heading</H1>');

$instr = qq{<h1 id=">">Heading</h1>};
@exp = (
    ['tag',  '<h1 id=">">', 'h1', 0 ],
    ['text', 'Heading'              ],
    ['tag',  '</h1>', 'h1', 0       ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<h1 id=">">Heading</h1> - Hard case with > in attribute value');

$instr = q{<hr/>};
@exp = (
    ['tag',  '<hr/>', 'hr', 1 ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<hr/> (simplest self closing tag 1/2)');

$instr = q{<hr />};
@exp = (
    ['tag',  '<hr />', 'hr', 1 ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<hr /> (simplest self closing tag 2/2)');

$instr = q{<div id="foo"/>};
@exp = (
    ['tag',  '<div id="foo"/>', 'div', 1 ],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<div id="foo"/> (self closing tag with attributes)');

$instr = qq{<div id="foobar" style=">"/>};
@exp = (
    ['tag',  '<div id="foobar" style=">"/>', 'div', 1],
);
$out = $m->_TokenizeHTML($instr);
is_deeply($out, \@exp, '<div id="foobar" style=">"/> (batshit mad self closing tag)');    

# TODO
# Add tests for entity declerations, doctypes and other things that we find?

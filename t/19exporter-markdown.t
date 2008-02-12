use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use_ok( 'Text::Markdown', 'markdown' );

my $instr = q{A trivial block of text};
my $outstr = q{<p>A trivial block of text</p>};

lives_ok {
    $outstr = markdown($instr);
} 'Functional markdown works without an exception';

chomp($outstr);

is(
    $outstr => '<p>' . $instr . '</p>', 
    'exported markdown function works'
);

{
    local $TODO = 'Broken here';
    $outstr = '';
    lives_ok {
        $outstr = Text::Markdown->markdown($instr);
    } 'Lives (class method)';

    chomp($outstr);

    is($outstr, '<p>' . $instr . '</p>', 'Text::Markdown->markdown() works (as class method)');
};

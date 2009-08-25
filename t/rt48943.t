use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::Markdown', 'markdown' );

my $str   = '<h1 class=center>foo</h1>';
my $m     = Text::Markdown->new;
my $html1 = $m->markdown($str);
like( $html1, qr/^$str/ );

warn $html1;

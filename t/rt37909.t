use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::Markdown', 'markdown' );

my $m     = Text::Markdown->new;
my $html1 = $m->markdown('<a+b@c.org>');
like( $html1, qr/<p><a href=".+&#.+">.+&#.+<\/a><\/p>/ );


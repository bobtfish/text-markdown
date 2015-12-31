use strict;
use warnings;
use Test::More tests => 3;
use Text::Markdown;
use Test::NoWarnings;

my $m = Text::Markdown->new;
ok $m->markdown(''), 'Parse empty string';
ok $m->markdown(undef), 'Parse undef';

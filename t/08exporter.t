use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $str;
lives_ok {
    $str = markdown(q{A trivial block of text});
} 'Functional markdown works without an exception';

is($str, q{<p>A trivial block of text</p>}, 'exported markdown function works');

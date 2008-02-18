use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new;
my $html1 = $m->markdown(<<"EOF");
Foo

Bar
EOF

is( $html1, <<"EOF" );
<p>Foo</p>

<p>Bar</p>
EOF

my $html2 = $m->markdown(<<"EOF");
Foo

Bar
EOF

is( $html2, <<"EOF" );
<p>Foo</p>

<p>Bar</p>
EOF

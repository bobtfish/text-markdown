use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new;
my $html1 = $m->markdown(<<"EOF");
Foo

Bar
EOF

is( <<"EOF", $html1 );
<p>Foo</p>

<p>Bar</p>
EOF

my $html2 = markdown(<<"EOF");
Foo

Bar
EOF

is( <<"EOF", $html2 );
<p>Foo</p>

<p>Bar</p>
EOF

use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new;
my $html1 = $m->markdown(<<"EOF");
[test][] the link!
EOF

is( <<"EOF", $html1 );
<p>[test][] the link!</p>
EOF

my $html2 = $m->markdown(<<"EOF", {urls => {test => 'http://example.com'}});
[test][] the link!
EOF

is( <<"EOF", $html2 );
<p><a href="http://example.com">test</a> the link!</p>
EOF

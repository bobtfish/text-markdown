use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new(
    heading_ids             => 0,
    markdown_in_html_blocks => 1,
);
my $html1 = $m->markdown(<<"EOF");
<div>

Heading
=======

</div>
EOF

is( $html1, <<"EOF" );
<div>

<h1>Heading</h1>

</div>
EOF

{
    local $TODO = 'I would expect this to work, but it doesnt - bug!';
    my $html2 = $m->markdown(<<"EOF");
 <div>

Heading
=======

 </div>
EOF
    is( $html1, <<"EOF" );
<div>

<h1>Heading</h1>

</div>
EOF

};
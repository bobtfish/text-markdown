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

 * List item 1
 * List item 2

</div>
EOF

is( $html1, <<"EOF" );
<div>

<h1>Heading</h1>

<ul>
<li>List item 1</li>
<li>List item 2</li>
</ul>
</div>
EOF

    my $html2 = $m->markdown(<<"EOF");
 <div>

Heading
=======

 </div>
EOF
    is( $html2, <<"EOF" );
<div>

<h1>Heading</h1>

 </div>
EOF

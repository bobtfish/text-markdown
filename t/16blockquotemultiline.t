use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new(
    heading_ids             => 0,
    markdown_in_html_blocks => 1,
);

my $html1 = $m->markdown(<<"EOF");
```Foo```
EOF

is ($html1, <<"EOF");
<p><code>Foo</code></p>
EOF

my $html2 = $m->markdown(<<'EOF');
```You can have multi-line comments.
With stuff $which->looks('like', `code`);
```
EOF

{
    local $TODO = 'known bug';
    is( $html2, <<'EOF'' );
<p><code>You can have multi-line comments.
With stuff $which->looks('like', `code`);
</p></code>
EOF
};


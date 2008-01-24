use Test::More tests => 3;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new(
    heading_ids             => 0,
);
my $html1 = $m->markdown(<<"EOF");
I wrote the following markdown code.

- a
- b

foobar

1. 1
2. 2

I expected that Text-Markdown would produce the following HTML
EOF

is($html1, <<"EOF");
<p>I wrote the following markdown code.</p>

<ul>
<li>a</li>
<li>b</li>
</ul>

<p>foobar</p>

<ol>
<li>1</li>
<li>2</li>
</ol>

<p>I expected that Text-Markdown would produce the following HTML</p>
EOF

my $html2 = $m->markdown(<<"EOF");
I wrote the following markdown code.

- a
- b

1. 1
2. 2

I expected that Text-Markdown would produce the following HTML
EOF

{
    local $TODO = 'Known bug in lists';
is($html2, <<"EOF");
<p>I wrote the following markdown code.</p>

<ul>
<li>a</li>
<li>b</li>
</ul>

<ol>
<li>1</li>
<li>2</li>
</ol>

<p>I expected that Text-Markdown would produce the following HTML</p>
EOF

};
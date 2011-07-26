use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::Markdown' );

my $m     = Text::Markdown->new(escape_html => 1);
my $html1 = $m->markdown(<<"EOF");
# paragraph
<strong>escape</strong>

# code block
    <strong>escape</strong>

# code span
`<strong>escape</strong>`

# list
- <strong>escape</strong>
    - <strong>escape</strong>

EOF

my $want = <<'EOF';
<h1>paragraph</h1>

<p>&lt;strong&gt;escape&lt;/strong&gt;</p>

<h1>code block</h1>

<pre><code>&lt;strong&gt;escape&lt;/strong&gt;
</code></pre>

<h1>code span</h1>

<p><code>&lt;strong&gt;escape&lt;/strong&gt;</code></p>

<h1>list</h1>

<ul>
<li>&lt;strong&gt;escape&lt;/strong&gt;
<ul>
<li>&lt;strong&gt;escape&lt;/strong&gt;</li>
</ul></li>
</ul>
EOF

is($html1, $want, "we can use numbering from start marker");

use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'Text::Markdown' );

my $m     = Text::Markdown->new(secure => 1);
my $html1 = $m->markdown(<<'EOF');
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

my $want1 = <<'EOF';
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

is($html1, $want1, "escape html");

my $html2 = $m->markdown(<<'EOF');
- <javascript:alert(0)>
- <http://example.org>
- <https://example.org>
- <ftp://example.org>
- [Test](javascript:alert(0))
- [Test](/rel)
- [Test](#id)
- [Test](http://example.org)
- [Test](https://example.org)
- [Test](ftp://example.org)
EOF

my $want2 = <<'EOF';
<ul>
<li>&lt;javascript:alert(0)&gt;</li>
<li><a href="http://example.org">http://example.org</a></li>
<li><a href="https://example.org">https://example.org</a></li>
<li><a href="ftp://example.org">ftp://example.org</a></li>
<li><a href="">Test</a></li>
<li><a href="/rel">Test</a></li>
<li><a href="#id">Test</a></li>
<li><a href="http://example.org">Test</a></li>
<li><a href="https://example.org">Test</a></li>
<li><a href="ftp://example.org">Test</a></li>
</ul>
EOF

is($html2, $want2, "allow hash or relative or absolute link.");
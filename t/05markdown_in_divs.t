use strict;
use warnings;
use Test::More tests => 23;
use Test::Differences;
use FindBin '$Bin';
use lib "$Bin/../lib";

use_ok 'Text::Markdown';

my $m    = Text::Markdown->new();
my ($html, $test);

#-------------------------------------------------------------------------------
$test = "sanity check: markown in block elements doesn't get interpreted";
$html = $m->markdown(<<"EOF");
<h2>
Literal *asterisks*
and _underscores_
</h2>
EOF
eq_or_diff $html, <<'EOF', $test;
<h2>
Literal *asterisks*
and _underscores_
</h2>
EOF


#-------------------------------------------------------------------------------
$test = 'markdown on in div - generate <p> tags';
$html = $m->markdown(<<"EOF");
some text here

<div markdown="1">
Interpreted *asterisks*
and _underscores_
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>some text here</p>

<div>
<p>Interpreted <em>asterisks</em>
and <em>underscores</em></p>
</div>
EOF


#-------------------------------------------------------------------------------
$test = 'markdown on in h2 - no <p> tags in h2';
$html = $m->markdown(<<"EOF");
some text here

<h2 markdown="on">
Interpreted *asterisks*
and _underscores_
</h2>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>some text here</p>

<h2>
Interpreted <em>asterisks</em>
and <em>underscores</em>
</h2>
EOF


#-------------------------------------------------------------------------------
# "block-level HTML elements — e.g. <div>, <table>, <pre>, <p>, etc. — must be separated
# from surrounding content by blank lines, and the start and end tags of the block
# should not be indented with tabs or spaces." -- http://daringfireball.net/projects/markdown/syntax#html
$test = 'some characters before an <h2> make the h2 an ignored element';
$html = $m->markdown(<<"EOF");
stuff<h2>
Interpreted *asterisks* and _underscores_
because HTML block elements must be separated from surrounding content by blank lines
</h2>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>stuff<h2>
Interpreted <em>asterisks</em> and <em>underscores</em>
because HTML block elements must be separated from surrounding content by blank lines
</h2></p>
EOF


#-------------------------------------------------------------------------------
$test = "adding markdown='on' if there were some characters before the h2, doesn't change anything. markdown='on' won't be removed.";
$html = $m->markdown(<<"EOF");
stuff<h2 markdown="on">
Interpreted *asterisks* and _underscores_, and markdown="on" left alone
because this wasn't a block HTML element in the first place
</h2>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>stuff<h2 markdown="on">
Interpreted <em>asterisks</em> and <em>underscores</em>, and markdown="on" left alone
because this wasn't a block HTML element in the first place
</h2></p>
EOF


#-------------------------------------------------------------------------------
$test = '<hr> in span-level HTML';
$html = $m->markdown(<<"EOF");
<span style="color: red">
Interpreted *asterisks*.
<hr>
Interpreted _underscores_.
</span>
EOF
eq_or_diff $html, <<'EOF', $test;
<p><span style="color: red">
Interpreted <em>asterisks</em>.
<hr>
Interpreted <em>underscores</em>.
</span></p>
EOF


#-------------------------------------------------------------------------------
$test = '<hr> in block-level HTML with markdown="on"';
$html = $m->markdown(<<"EOF");
<div markdown="on">
Interpreted *asterisks*.
<hr>
Interpreted _underscores_.
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<div>
<p>Interpreted <em>asterisks</em>.
<hr>
Interpreted <em>underscores</em>.</p>
</div>
EOF


#-------------------------------------------------------------------------------
$test = "don't mess with the markdown attribute if part of code span or block";
$html = $m->markdown(<<"EOF");
A `<div markdown="1">` will interpret Markdown, unless in a code block.

    <div markdown="1">
    The *above* is a '<div>' tag
    in a code block</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>A <code>&lt;div markdown="1"&gt;</code> will interpret Markdown, unless in a code block.</p>

<pre><code>&lt;div markdown="1"&gt;
The *above* is a '&lt;div&gt;' tag
in a code block&lt;/div&gt;
</code></pre>
EOF


#-------------------------------------------------------------------------------
$test = "leave [div] alone, it's not <div>";
$html = $m->markdown(<<"EOF");
[div markdown="1"]
The above is NOT a <div>!
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<p>[div markdown="1"]
The above is NOT a <div>!
</div></p>
EOF


#-------------------------------------------------------------------------------
$test = "leave !div! alone, it's not <div>, and it's in code too";
$html = $m->markdown(<<"EOF");
    !div markdown="1"!
    The above is NOT a <div>!
    </div>
EOF
eq_or_diff $html, <<'EOF', $test;
<pre><code>!div markdown="1"!
The above is NOT a &lt;div&gt;!
&lt;/div&gt;
</code></pre>
EOF


#-------------------------------------------------------------------------------
$test = 'start interpreting Markdown without blank line sandwiching';
$html = $m->markdown(<<"EOF");
*outside of the div*
<div markdown="1">
*start interpreting Markdown without blank line sandwiching*
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<p><em>outside of the div</em></p>

<div>
<p><em>start interpreting Markdown without blank line sandwiching</em></p>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with inner list';
$html = $m->markdown(<<"EOF");
<div markdown="1">

1. this
2. is a list

</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<div>
<ol>
<li>this</li>
<li>is a list</li>
</ol>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with inner code block';
$html = $m->markdown(<<"EOF");
<div markdown="1">

    code line 1
    code line 2

</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<div>
<pre><code>code line 1
code line 2
</code></pre>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with inner blockquote';
$html = $m->markdown(<<"EOF");
<div markdown="1">
> Thus spoke Lincoln
</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<div>
<blockquote>
  <p>Thus spoke Lincoln</p>
</blockquote>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with inner block HTML';
$html = $m->markdown(<<"EOF");
<div markdown="1">
*interpreted*

<div><script>var i = _count_ ;</script></div>
</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<div>
<p><em>interpreted</em></p>

<div><script>var i = _count_ ;</script></div>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with inner <div>, which ends with exactly one line';
$html = $m->markdown(<<"EOF");
<div markdown="1">
<div><script>var i = _count_ ;</script></div>


</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<div>
<div><script>var i = _count_ ;</script></div>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> comprehensive';
$html = $m->markdown(<<"EOF");
*marked down text*

<div markdown="1">

* this
* is a list

</div>

<div markdown="0">
*no markdown interpretation here*
</div>

<div>
*no markdown interpretation here*
</div>

<div markdown="1" class="navbar">
1. Home
2. About
</div>

<div markdown="0" clas="web_counter">
*no markdown interpretation here*
</div>
EOF

eq_or_diff $html, <<'EOF', $test;
<p><em>marked down text</em></p>

<div>
<ul>
<li>this</li>
<li>is a list</li>
</ul>
</div>

<div>
*no markdown interpretation here*
</div>

<div>
*no markdown interpretation here*
</div>

<div class="navbar">
<ol>
<li>Home</li>
<li>About</li>
</ol>
</div>

<div clas="web_counter">
*no markdown interpretation here*
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div markdown="1"> with multiple lines of attributes';
$html = $m->markdown(<<"EOF");
<div markdown="1"
     class="navbar"
>
*multiple lines of attributes*
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<div
     class="navbar"
>
<p><em>multiple lines of attributes</em></p>
</div>
EOF


#-------------------------------------------------------------------------------
$test = '<div \n\n...\n markdown="1"> - can put the markdown="1" attribute anywhere';
$html = $m->markdown(<<"EOF");
<div class="navbar"
    markdown="1"
>
*multiple lines of attributes*
</div>
EOF
eq_or_diff $html, <<'EOF', $test;
<div class="navbar"
>
<p><em>multiple lines of attributes</em></p>
</div>
EOF


#-------------------------------------------------------------------------------
$test = "sanity check: just code";
$html = $m->markdown(<<"EOF");
Below is code

    code

Above was code
EOF
eq_or_diff $html, <<'EOF', $test;
<p>Below is code</p>

<pre><code>code
</code></pre>

<p>Above was code</p>
EOF


#-------------------------------------------------------------------------------
$test = "without markdown on - cannot generate link";
$html = $m->markdown(<<"EOF");
<div style="margin-top: 50px; margin-left: 400px;">

[Text::Markdown][cpan-text-markdown] is really cool!

</div>

[cpan-text-markdown]:    https://metacpan.org/module/Text::Markdown

EOF
eq_or_diff $html, <<'EOF', $test;
<div style="margin-top: 50px; margin-left: 400px;">

[Text::Markdown][cpan-text-markdown] is really cool!

</div>
EOF


#-------------------------------------------------------------------------------
$test = "markdown on - generat link";
$html = $m->markdown(<<"EOF");
<div markdown="1" style="margin-top: 50px; margin-left: 400px;">

[Text::Markdown][cpan-text-markdown] is really cool!

</div>

[cpan-text-markdown]:    https://metacpan.org/module/Text::Markdown
EOF
eq_or_diff $html, <<'EOF', $test;
<div style="margin-top: 50px; margin-left: 400px;">
<p><a href="https://metacpan.org/module/Text::Markdown">Text::Markdown</a> is really cool!</p>
</div>
EOF

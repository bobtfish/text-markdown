use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    unless(eval q{ use Test::Differences; unified_diff; 1 }) {
        note 'Test::Differences recommended';
        *eq_or_diff = \&is_deeply;
    }
}

use_ok('Text::Markdown', 'markdown');

my $mkdn = <<'END';
Newlines
--------

The biggest difference that GFM introduces is in the handling of linebreaks. With SM you can hard
wrap paragraphs of text and they will be combined into a single paragraph. We find this to be the
cause of a huge number of unintentional formatting errors. GFM treats newlines in paragraph-like
content as real line breaks, which is probably what you intended.

The next paragraph contains two phrases separated by a single newline character:

    Roses are red
    Violets are blue

becomes

Roses are red
Violets are blue
END

{
    my $m = Text::Markdown->new( break_at_newlines => 0 );

    my $html = $m->markdown($mkdn);

    eq_or_diff( $html, <<'EOF', 'off' );
<h2>Newlines</h2>

<p>The biggest difference that GFM introduces is in the handling of linebreaks. With SM you can hard
wrap paragraphs of text and they will be combined into a single paragraph. We find this to be the
cause of a huge number of unintentional formatting errors. GFM treats newlines in paragraph-like
content as real line breaks, which is probably what you intended.</p>

<p>The next paragraph contains two phrases separated by a single newline character:</p>

<pre><code>Roses are red
Violets are blue
</code></pre>

<p>becomes</p>

<p>Roses are red
Violets are blue</p>
EOF
}

{
    my $m = Text::Markdown->new( break_at_newlines => 1 );

    my $html = $m->markdown($mkdn);

    eq_or_diff( $html, <<'EOF', 'on');
<h2>Newlines</h2>

<p>The biggest difference that GFM introduces is in the handling of linebreaks. With SM you can hard <br />
wrap paragraphs of text and they will be combined into a single paragraph. We find this to be the <br />
cause of a huge number of unintentional formatting errors. GFM treats newlines in paragraph-like <br />
content as real line breaks, which is probably what you intended.</p>

<p>The next paragraph contains two phrases separated by a single newline character:</p>

<pre><code>Roses are red
Violets are blue
</code></pre>

<p>becomes</p>

<p>Roses are red <br />
Violets are blue</p>
EOF
}

{
    my $m = Text::Markdown->new();

    my $html = $m->markdown($mkdn);

    eq_or_diff( $html, <<'EOF', 'default' );
<h2>Newlines</h2>

<p>The biggest difference that GFM introduces is in the handling of linebreaks. With SM you can hard
wrap paragraphs of text and they will be combined into a single paragraph. We find this to be the
cause of a huge number of unintentional formatting errors. GFM treats newlines in paragraph-like
content as real line breaks, which is probably what you intended.</p>

<p>The next paragraph contains two phrases separated by a single newline character:</p>

<pre><code>Roses are red
Violets are blue
</code></pre>

<p>becomes</p>

<p>Roses are red
Violets are blue</p>
EOF
}

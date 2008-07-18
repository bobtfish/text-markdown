use strict;
use warnings;
use Test::More tests => 4;

use_ok( 'Text::Markdown' );

my $m = Text::Markdown->new( tab_width => 2 );
my $instr = q{start

  <h1>HTML block</h1>

end
};

my $expstr = q{<p>start</p>

<pre><code>&lt;h1&gt;HTML block&lt;/h1&gt;
</code></pre>

<p>end</p>
};

is($m->markdown($instr) => $expstr, 'Correct (constructor)');
is(Text::Markdown->new->markdown($instr, { tab_width => 2}) => $expstr, 'Correct (markdown method option)');

my $txt =  $m->markdown(<<'END_MARKDOWN');
This is a para.

  This is code.
  ---
  This is code.

This is a para.
END_MARKDOWN

unlike($txt, qr{<hr}, "no HR elements when the hr is in a code block");
 
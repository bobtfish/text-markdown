use strict;
use warnings;
use Test::More tests => 3;

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
 
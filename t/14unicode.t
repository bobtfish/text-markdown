use utf8;
use strict;
use warnings;
use Test::More tests => 3;

use_ok('Text::MultiMarkdown', 'markdown');

my $m = Text::MultiMarkdown->new;
my $html1;
$html1 = eval { $m->markdown(<<"EOF"); };
> Fo—o

μορεοϋερ

> ßåř
EOF

ok(!$@, "No exception from markdown ($@)");

is( $html1, <<"EOF" );
<blockquote>
  <p>Fo—o</p>
</blockquote>

<p>μορεοϋερ</p>

<blockquote>
  <p>ßåř</p>
</blockquote>
EOF

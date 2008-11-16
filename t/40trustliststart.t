use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::Markdown' );

my $m     = Text::Markdown->new(trust_list_start_value => 1);
my $html1 = $m->markdown(<<"EOF");
1. this
2. is a list

Paragraph.

3. and we
4. pick up

EOF

my $want = <<'EOF';
<ol start='1'>
<li>this</li>
<li>is a list</li>
</ol>

<p>Paragraph.</p>

<ol start='3'>
<li>and we</li>
<li>pick up</li>
</ol>
EOF

is($html1, $want, "we can use numbering from start marker");

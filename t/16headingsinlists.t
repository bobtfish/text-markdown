use warnings;
use strict;
use Test::More tests => 2;

use_ok('Text::MultiMarkdown', 'markdown');

my $m = Text::MultiMarkdown->new(
    heading_ids => 0
);

# This case works.

my $html1 = $m->markdown(<<"EOF");
- # Heading 1

- ## Heading 2
EOF

is( $html1, <<"EOF" );
<ul>
<li><h1>Heading 1</h1></li>
<li><h2>Heading 2</h2></li>
</ul>
EOF

# This case fails.

my $html2 = $m->markdown(<<"EOF");
- # Heading 1
- ## Heading 2
EOF

is( $html2, <<"EOF" );
<ul>
<li><h1>Heading 1</h1></li>
<li><h2>Heading 2</h2></li>
</ul>
EOF
s
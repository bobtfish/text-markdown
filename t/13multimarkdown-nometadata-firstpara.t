use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $m     = Text::MultiMarkdown->new;

# A line of whitespace should cause metadata to be skipped..
my $html1 = $m->markdown(<<"EOF");
    
Simple block on one line:

<div>foo</div>
EOF

is( $html1, <<"EOF" );
<p>Simple block on one line:</p>

<div>foo</div>
EOF

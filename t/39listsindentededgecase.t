use strict;
use warnings;
use Test::More tests => 2;

# Again, I'd like to do what the stricter parser / functional markdowns do here..
# http://babelmark.bobtfish.net/?markdown=+8.+item+1%0D%0A+9.+item+2%0D%0A10.+item+2a&normalize=on

use_ok('Text::MultiMarkdown', 'markdown');

my $m = Text::MultiMarkdown->new();
my $html1 = $m->markdown(<<"EOF");
 8. item 1
 9. item 2
10. item 2a
EOF

{
    local $TODO = 'Does not work as expected in current Markdown, known bug.';

    is( $html1, <<"EOF" );
<ol>
<li>item 1</li>

<li>item 2</li>

<li>item 2a</li>
</ol>
EOF

};

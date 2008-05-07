use strict;
use warnings;
use Test::More tests => 2;

# I would like to do what Pandoc etc do here...
# http://babelmark.bobtfish.net/?markdown=%2B+++item+1%0D%0A%0D%0A++++%2B+++item+2%0D%0A%0D%0A+*+++*+++*+++*+++*&normalize=on

use_ok('Text::MultiMarkdown', 'markdown');

my $m = Text::MultiMarkdown->new();
my $html1 = $m->markdown(<<"EOF");
+   item 1

    +   item 2

 *   *   *   *   *
EOF

{
    local $TODO = 'Does not work as expected in current Markdown, known bug.';

    is( $html1, <<"EOF" );
<ul>
<li>
<p>item 1</p>

<ul>
<li>item 2</li>
</ul>
</li>
</ul>

<hr/>
EOF

};

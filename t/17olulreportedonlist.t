use strict;
use warnings;
use Test::More tests => 6;

use_ok('Text::MultiMarkdown', 'markdown');

# This case was reported broken on the markdown mailing list
my $m = Text::MultiMarkdown->new();
my $html1 = $m->_DoLists(<<"EOF");
foo

- a
- b

1. 1
2. 2

bar
EOF

{
    local $TODO = 'Does not work as expected in current Markdown, known bug.';

    is( $html1, <<"EOF" );
foo

<ul>
<li>a</li>
<li>b</li>
</ul>

<ol>
<li>1</li>
<li>2</li>
</ol>

bar
EOF

my $html2 = $m->_DoLists(<<'EOF');
foo

   1. Item 1
   
   2. Item 2

bar
EOF

is( $html2, <<"EOF" );
foo

<ol>
<li><p>Item 1</p></li>
<li><p>Item 2</p></li>
</ol>

bar
EOF

my $html3 = $m->_DoLists(<<'EOF');
foo

bar
EOF

is( $html3, <<'EOF' );
foo

bar
EOF

my $html4 = $m->_DoLists(<<'EOF');
foo

1.	Item 1, graf one.

	Item 2. graf two. The quick brown fox jumped over the lazy dog's
	back.
	
2.	Item 2.

3.	Item 3.

bar
EOF

is( $html4, <<'EOF' );
foo

<ol>
<li><p>Item 1, graf one.</p>

<p>Item 2. graf two. The quick brown fox jumped over the lazy dog's
back.</p></li>
<li><p>Item 2.</p></li>
<li><p>Item 3.</p></li>
</ol>

bar
EOF

print "\n" x 20;

my $html5 = $m->_DoLists(<<'EOF');
1. First
2. Second:
	* Fee
	* Fie
	* Foe
3. Third

EOF

is( $html5, <<'EOF' );
<ol>
<li>First</li>
<li>Second:
<ul>
<li>Fee</li>
<li>Fie</li>
<li>Foe</li>
</ul></li>
<li>Third</li>
</ol>
EOF

};

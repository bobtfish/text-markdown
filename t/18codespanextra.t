# Test a 'bug' reported by Nathan Waddell/J. Shirley from the #catalyst-dev community.
# I don't think that this is a bug at all ;)
use strict;
use warnings;
use Test::More tests => 4;

use_ok('Text::MultiMarkdown', 'markdown');

my $m = Text::MultiMarkdown->new(
    use_metadata => 0,
);

my $html1 = $m->markdown(<<'EOF');
`cpan Module::Install`
`cpan Task::Catalyst`
EOF

is( $html1, <<'EOF' );
<p><code>cpan Module::Install</code>
<code>cpan Task::Catalyst</code></p>
EOF

my $html2 = $m->markdown(<<'EOF');
`cpan Module::Install`

`cpan Task::Catalyst`
EOF

is( $html2, <<'EOF' );
<p><code>cpan Module::Install</code></p>

<p><code>cpan Task::Catalyst</code></p>
EOF

my $html3 = $m->markdown(<<'EOF');
`cpanp -i Module::Install`
`cpanp -i Task::Catalyst`
EOF

is( $html3, <<'EOF' );
<p><code>cpanp -i Module::Install</code>
<code>cpanp -i Task::Catalyst</code></p>
EOF


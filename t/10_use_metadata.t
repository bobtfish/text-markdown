use strict;
use warnings;
use Test::More tests => 6;

use_ok( 'Text::MultiMarkdown');

my $instr = qq{use wikilinks: on\nbase url: http://www.test.com/\n\nA trivial block of text with a WikiWord};

my $m = Text::MultiMarkdown->new(
    use_metadata => 1,
);
my $expstr = qq{<p>A trivial block of text with a <a href="http://www.test.com/WikiWord">WikiWord</a></p>\n};
is($m->markdown($instr), $expstr, 'Markdown with wiki links, and base url, metadata switched on in instance');

$m = Text::MultiMarkdown->new(
    use_metadata => 0,
);
my $expstr2 = qq{<p>use wikilinks: on\nbase url: http://www.test.com/</p>\n\n<p>A trivial block of text with a WikiWord</p>\n};
is($m->markdown($instr), $expstr2, 'Markdown with wiki links, with base url in instance (no metadata)');

is($m->markdown($instr, { use_metadata => 1 }), $expstr, 'Markdown with wiki links, and base url, metadata switched on in options');

is($m->markdown($instr), $expstr2, 'Markdown with wiki links, with base url in instance (no metadata) - try 2 to ensure option to markdown does not frob setting');

{
    local $TODO = 'This would be useful to support';
    $m = Text::MultiMarkdown->new(
        use_metadata   => 0,
        strip_metadata => 1,  
    );
    $expstr = qq{<p>A trivial block of text with a WikiWord</p>\n};
    is($m->markdown($instr), $expstr, 'Markdown with wiki links, with base url in instance');
};

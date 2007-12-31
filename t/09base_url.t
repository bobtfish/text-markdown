use strict;
use warnings;
use Test::More tests => 4;

use_ok( 'Text::MultiMarkdown');

my $instr = q{A trivial block of text with a WikiWord};
my $m = Text::MultiMarkdown->new(
    use_wikilinks => 1,
);
my $outstr = qq{<p>A trivial block of text with a <a href="WikiWord">WikiWord</a></p>\n};
is(
    $m->markdown($instr) => $outstr, 
    'Markdown with wiki links, no base url'
);

$m = Text::MultiMarkdown->new(
    use_wikilinks => 1,
    base_url => 'http://www.test.com/',
);
$outstr = qq{<p>A trivial block of text with a <a href="http://www.test.com/WikiWord">WikiWord</a></p>\n};
is(
    $m->markdown($instr) => $outstr, 
    'Markdown with wiki links, with base url in instance'
);

$m = Text::MultiMarkdown->new(
    use_wikilinks => 1,
    use_metadata   => 1,
);
$instr = qq{base url: http://www.test.com/\n\n} . $instr;
$outstr = qq{base url: http://www.test.com/<br />\n\n} . $outstr;
is(
    $m->markdown($instr) => $outstr, 
    'Markdown with wiki links, with base url in metadata'
);

use strict;
use warnings;
use Test::More tests => 7;

#1
use_ok( 'Text::MultiMarkdown');

my $instr = qq{use wikilinks: on\nbase url: http://www.test.com/\n\nA trivial block of text with a WikiWord};

my $m = Text::MultiMarkdown->new(
    use_metadata => 1,
);
my $expstr = qq{base url: http://www.test.com/<br />\nuse wikilinks: on<br />\n
<p>A trivial block of text with a <a href="http://www.test.com/WikiWord">WikiWord</a></p>\n};
is( #2
    $m->markdown($instr) => $expstr, 
    'Markdown with wiki links, and base url, metadata switched on in instance'
);

$m = Text::MultiMarkdown->new(
    use_metadata => 0,
);
my $expstr2 = qq{<p>use wikilinks: on\nbase url: http://www.test.com/</p>\n\n<p>A trivial block of text with a WikiWord</p>\n};
is( #3
    $m->markdown($instr) => $expstr2, 
    'Markdown with wiki links, with base url in instance (no metadata)'
);
is( #4
    $m->markdown($instr, { use_metadata => 1 }) => $expstr, 
    'Markdown with wiki links, and base url, metadata switched on in options'
);
is( #5
    $m->markdown($instr) => $expstr2, 
    'Markdown with wiki links, with base url in instance (no metadata) - try 2 to ensure option to markdown does not frob setting'
);

{
    local $TODO = 'This would be useful to support';
    $m = Text::MultiMarkdown->new(
        use_metadata   => 0,
        strip_metadata => 1,  
    );
    $expstr = qq{<p>A trivial block of text with a WikiWord</p>\n};
    is( #6
        $m->markdown($instr) => $expstr, 
        'Markdown with wiki links, with metadata off and stripped'
    );
    
    $expstr = qq{<p>A trivial block of text with a <a href="http://www.test.com/WikiWord">WikiWord</a></p>\n};
    is( #7
        $m->markdown($instr, { use_metadata => 1 }) => $expstr, 
        'Markdown with wiki links, with metadata on but stripped'
    );
};

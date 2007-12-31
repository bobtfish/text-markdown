use strict;
use warnings;
use Test::More tests => 9;

use_ok( 'Text::MultiMarkdown', 'markdown' );

my $page = 'WikiWord';

# FIXME - test 
#   . No wiki links in headers?
#   . No wiki links in code section

# Normal (no wiki links)
my $m     = Text::MultiMarkdown->new;

my $nohtmlwiki = $m->markdown($page);
ok($nohtmlwiki !~ /<a/, 'No link where no htmlwiki');

# Note - we adding metadata ends up with the output page having that metadata inside it..
#        therefore we strip the output to the first line containing /WikiWord/ here..
my $htmlwiki = (grep /WikiWord/, split(/\n/, $m->markdown("use wikilinks: true\n\n" . $page)))[0] . "\n";
ok($htmlwiki =~ /<a/, 'has a link where expected');

is($m->markdown($page), $nohtmlwiki, 'use wikilinks does not toggle pref');

is($m->markdown($page, { use_wikilinks => 1 }) => $htmlwiki, 
    'use_wikilinks pref in ->markdown produces same out as metadata');

is($m->markdown($page, { use_wikilinks => 0 }) => $nohtmlwiki,
    'use_wikilinks = 0 pref in ->markdown produces same out as no metadata');

$m = Text::MultiMarkdown->new(use_wikilinks => 1);
is($m->markdown($page) => $htmlwiki, 
    'use wikiwords pref in constructor produces same out as metadata');
is($m->markdown($page, { use_wikilinks => 0 }) => $nohtmlwiki, 
    'not use wikilinks pref in markdown produces same out as no metadata when instance has wikilinks enabled');

is($m->markdown('\\' . $page) => $nohtmlwiki,
    'Wiki word escaping works as expected');
# http://bugs.debian.org/459885
use strict;
use warnings;
use Test::More tests => 3;

use_ok('Text::Markdown');

my $m = Text::Markdown->new;

my $in = q{[link 
text] [link
id]

[link id]: /someurl/
};
my $ex = q{<p><a href="/someurl/">link 
text</a></p>
};

is($m->markdown($in), $ex, 'http://bugs.debian.org/459885 - Line breaks in reference link ids (single line breaks)');

{
    local $TODO = 'This should probably also pass';
$in = q{[link 
text] [link

id]

[link  id]: /someurl/
};
$ex = q{<p><a href="/someurl/">link 
text</a></p>
};

is($m->markdown($in), $ex, 'http://bugs.debian.org/459885 - Line breaks in reference link ids (multi line breaks)');

};
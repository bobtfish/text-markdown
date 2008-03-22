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

$in = qq{Bla, bla, bla, bla, bla, bla, bla, bla, bla, bla bla. This is [my  \nUniversity][].

  [my university]: http://www.ua.es
};
$ex = q{<p>Bla, bla, bla, bla, bla, bla, bla, bla, bla, bla bla. This is <a href="http://www.ua.es">my <br />
University</a>.</p>
};

is($m->markdown($in), $ex, 'http://bugs.debian.org/459885 - Line breaks in reference link ids (multiple trailing spaces and line breaks)');

$in = qq{Bla, bla, bla, bla, bla, bla, bla, bla, bla, bla bla. This is [my  \nUniversity].

  [my university]: http://www.ua.es
};
$ex = q{<p>Bla, bla, bla, bla, bla, bla, bla, bla, bla, bla bla. This is <a href="http://www.ua.es">my <br />
University</a>.</p>
};

is($m->markdown($in), $ex, 'http://bugs.debian.org/459885 - Line breaks in shortcut reference link ids (multiple trailing spaces and line breaks)');



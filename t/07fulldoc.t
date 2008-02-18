use strict;
use warnings;
use Text::MultiMarkdown;

print Text::MultiMarkdown::_DoBlockQuotes(join("\n", <DATA>));

__DATA__
> block quoted text
>
> in multiple paragraphs
> and across multiple lines
>
> > and at
>> multiple levels.

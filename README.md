# NAME

Text::Markdown - Convert Markdown syntax to (X)HTML

# SYNOPSIS

```perl
use Text::Markdown 'markdown';
my $html = markdown($text);

use Text::Markdown 'markdown';
my $html = markdown( $text, {
    empty_element_suffix => '>',
    tab_width => 2,
} );

use Text::Markdown;
my $m = Text::Markdown->new;
my $html = $m->markdown($text);

use Text::Markdown;
my $m = Text::MultiMarkdown->new(
    empty_element_suffix => '>',
    tab_width => 2,
);
my $html = $m->markdown( $text );
```

# DESCRIPTION

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, \*emphasis\*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

# SYNTAX

This module implements the 'original' Markdown markdown syntax from:

```
http://daringfireball.net/projects/markdown/
```

Note that [Text::Markdown](https://metacpan.org/pod/Text::Markdown) ensures that the output always ends with
**one** newline. The fact that multiple newlines are collapsed into one
makes sense, because this is the behavior of HTML towards whitespace. The
fact that there's always a newline at the end makes sense again, given
that the output will always be nested in a **block**-level element (as
opposed to an inline element). That block element can be a `<p>`
(most often), or a `<table>`.

Markdown is **not** interpreted in HTML block-level elements, in order for
chunks of pasted HTML (e.g. JavaScript widgets, web counters) to not be
magically (mis)interpreted. For selective processing of Markdown in some,
but not other, HTML block elements, add a `markdown` attribute to the block
element and set its value to `1`, `on` or `yes`:

```
<div markdown="1" class="navbar">
* Home
* About
* Contact
<div>
```

The extra `markdown` attribute will be stripped when generating the output.

# OPTIONS

Text::Markdown supports a number of options to its processor which control
the behaviour of the output document.

These options can be supplied to the constructor, or in a hash within
individual calls to the ["markdown"](#markdown) method. See the SYNOPSIS for examples
of both styles.

The options for the processor are:

- empty\_element\_suffix

    This option controls the end of empty element tags:

    ```
    '/>' for XHTML (default)
    '>' for HTML
    ```

- tab\_width

    Controls indent width in the generated markup. Defaults to 4.

- trust\_list\_start\_value

    If true, ordered lists will use the first number as the starting point for
    numbering.  This will let you pick up where you left off by writing:

    ```
    1. foo
    2. bar

    some paragraph

    3. baz
    6. quux
    ```

    (Note that in the above, quux will be numbered 4.)

# METHODS

## new

A simple constructor, see the SYNTAX and OPTIONS sections for more information.

## markdown

The main function as far as the outside world is concerned. See the SYNOPSIS
for details on use.

## urls

Returns a reference to a hash with the key being the markdown reference
and the value being the URL.

Useful for building scripts which preprocess a list of links before the
main content. See `t/05options.t` for an example of this hashref being
passed back into the markdown method to create links.

# OTHER IMPLEMENTATIONS

Markdown has been re-implemented in a number of languages, and with a number of additions.

Those that I have found are listed below:

- C - <http://www.pell.portland.or.us/~orc/Code/discount>

    Discount - Original Markdown, but in C. Fastest implementation available, and passes MDTest.
    Adds its own set of custom features.

- python - <http://www.freewisdom.org/projects/python-markdown/>

    Python Markdown which is mostly compatible with the original, with an interesting extension API.

- ruby (maruku) - <http://maruku.rubyforge.org/>

    One of the nicest implementations out there. Builds a parse tree internally so very flexible.

- php - <http://michelf.com/projects/php-markdown/>

    A direct port of Markdown.pl, also has a separately maintained 'extra' version,
    which adds a number of features that were borrowed by MultiMarkdown.

- lua - <http://www.frykholm.se/files/markdown.lua>

    Port to lua. Simple and lightweight (as lua is).

- haskell - <http://johnmacfarlane.net/pandoc/>

    Pandoc is a more general library, supporting Markdown, reStructuredText, LaTeX and more.

- javascript - <http://www.attacklab.net/showdown-gui.html>

    Direct(ish) port of Markdown.pl to JavaScript

# BUGS

To file bug reports or feature requests please send email to:

```
bug-Text-Markdown@rt.cpan.org
```

Please include with your report: (1) the example input; (2) the output
you expected; (3) the output Markdown actually produced.

# VERSION HISTORY

See the Changes file for detailed release notes for this version.

# AUTHOR

```
John Gruber
http://daringfireball.net/

PHP port and other contributions by Michel Fortin
http://michelf.com/

MultiMarkdown changes by Fletcher Penney
http://fletcher.freeshell.org/

CPAN Module Text::MultiMarkdown (based on Text::Markdown by Sebastian
Riedel) originally by Darren Kulp (http://kulp.ch/)

Support for markdown="1" by Dan Dascalescu (http://dandascalescu.com)

This module is maintained by: Tomas Doran http://www.bobtfish.net/
```

# THIS DISTRIBUTION

Please note that this distribution is a fork of John Gruber's original Markdown project,
and it \*is not\* in any way blessed by him.

Whilst this code aims to be compatible with the original Markdown.pl (and incorporates
and passes the Markdown test suite) whilst fixing a number of bugs in the original -
there may be differences between the behaviour of this module and Markdown.pl. If you find
any differences where you believe Text::Markdown behaves contrary to the Markdown spec,
please report them as bugs.

Text::Markdown \*does not\* extend the markdown dialect in any way from that which is documented at
daringfireball. If you want additional features, you should look at [Text::MultiMarkdown](https://metacpan.org/pod/Text::MultiMarkdown).

# SOURCE CODE

You can find the source code repository for [Text::Markdown](https://metacpan.org/pod/Text::Markdown) and [Text::MultiMarkdown](https://metacpan.org/pod/Text::MultiMarkdown)
on GitHub at <http://github.com/bobtfish/text-markdown>.

# COPYRIGHT AND LICENSE

Original Code Copyright (c) 2003-2004 John Gruber
<http://daringfireball.net/>
All rights reserved.

MultiMarkdown changes Copyright (c) 2005-2006 Fletcher T. Penney
<http://fletcher.freeshell.org/>
All rights reserved.

Text::MultiMarkdown changes Copyright (c) 2006-2009 Darren Kulp
<http://kulp.ch> and Tomas Doran <http://www.bobtfish.net>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

\* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

\* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

\* Neither the name "Markdown" nor the names of its contributors may
  be used to endorse or promote products derived from this software
  without specific prior written permission.

This software is provided by the copyright holders and contributors "as
is" and any express or implied warranties, including, but not limited
to, the implied warranties of merchantability and fitness for a
particular purpose are disclaimed. In no event shall the copyright owner
or contributors be liable for any direct, indirect, incidental, special,
exemplary, or consequential damages (including, but not limited to,
procurement of substitute goods or services; loss of use, data, or
profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability, or tort (including
negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.

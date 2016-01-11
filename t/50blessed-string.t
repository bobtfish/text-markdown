use strict;
use warnings;
use utf8;
use Test::More;
use Text::Markdown qw(markdown);

plan tests => 1;

{
    # emulate class like Text::Xslate::Type::Raw
    package    #
      StringClass;

    use overload (
        q{""} => sub { ${ $_[0] } },
        fallback => 1,
    );
    sub new {
        my ($class, $str) = @_;
        bless \$str, $class;
    }
}

my $src = StringClass->new('foo');
is(markdown($src), "<p>foo</p>\n");


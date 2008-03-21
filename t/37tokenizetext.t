use strict;
use warnings;
use Text::MultiMarkdown ();
use Test::More tests => 11;

# Test the _TokenizeText routine This takes a chunk of text and splits it on line breaks, making
# a number of tokens.
#
# It gets fed the bits that _TokenizeHTML doesn't want to eat.
# 
# Outputs a list of ['text', $string], where $string is split on \n
#

my $m = Text::MultiMarkdown->new();

my $instr = qq{foobar};
my @exp = ( ['text', 'foobar'] );
my @out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'simplest case');

$instr = qq{foo\nbar};
@exp = ( ['text', 'foo'], ['text', "\n"], ['text', 'bar'] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\nbar');

$instr = qq{foo\n\n\n\nbar};
@exp = ( ['text', 'foo'], ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', 'bar'] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\n\n\n\nbar');

$instr = qq{\n\n\n\n};
@exp = ( ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', "\n"] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, '\n\n\n\n');

$instr = qq{\n\n\n\nfoo};
@exp = ( ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', 'foo'] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, '\n\n\n\nfoo');

$instr = qq{foo\n\n\n\n};
@exp = ( ['text', 'foo'], ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', "\n"] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\n\n\n\n');

$instr = qq{foo\nbar\n};
@exp = ( ['text', 'foo'], ['text', "\n"], ['text', 'bar'], ['text', "\n"] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\nbar\n');

$instr = qq{foo\n\n\n};
@exp = ( ['text', 'foo'], ['text', "\n"], ['text', "\n"], ['text', "\n"]);
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\n\n\n');

$instr = qq{\n\n\nbar};
@exp = ( ['text', "\n"], ['text', "\n"], ['text', "\n"], ['text', 'bar'] );
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, '\n\n\nbar');

$instr = q{code block


with a blank line
};
@out = $m->_TokenizeText($instr);
#use Data::Dumper;
#warn(Dumper(\@out));
@exp = map { ['text', $_] } ("code block", "\n", "\n", 
                             "\n", "with a blank line","\n");
is_deeply(\@out, \@exp, 'Real string (code block with blank line)');

# Test that we can deal with a large document. The first version of this function died due to deep recursion
my $itr = 5000;
$instr = qq{foo\n} x $itr;
my @partexp = ( ['text', 'foo'], ['text', "\n"] );
@exp = ();
for (my $i=0; $i < $itr; $i++) {
    push(@exp, @partexp);
}
@out = $m->_TokenizeText($instr);
is_deeply(\@out, \@exp, 'foo\n x ' . $itr);

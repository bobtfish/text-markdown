package Text::Markdown;
require 5.006_000;
use strict;
use warnings;
use base qw(Text::MultiMarkdown);

our $VERSION   = '1.0.12';
our @EXPORT_OK = qw(markdown);

=head1 NAME

Text::Markdown - Convert MultiMarkdown syntax to (X)HTML

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, *emphasis*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

This module implements the 'original' Markdown markdown syntax from:

    http://daringfireball.net/projects/markdown/
    
If you would like different options available / to control the parser
behavior more then you're recommended to look at the OPTIONS section in
the pod for L<Text::MultiMarkdown>

=head1 SYNTAX

For more information about Markdown's syntax, see:

    http://daringfireball.net/projects/markdown/

This documentation is going to be moved/copied into this module for clearer reading in a future release..

=head1 METHODS

=cut

my %force_opts = (
    use_metadata         => 0, # Treat the first lines of the document as normal.
    heading_ids          => 0, # Remove MultiMarkdown behavior change in <hX> tags.
    img_ids              => 0, # Remove MultiMarkdown behavior change in <img> tags.
    disable_tables       => 1, # Disable all the multimarkdown specific features.
    disable_footnotes    => 1, 
    disable_bibliography => 1,
);

=head2 new

Simple constructor. Takes the same arguments as the constructor of L<Text::MultiMarkdown>, however this module
overrides the following settings:

=over

=item use_metadata => 0

=item heading_ids => 0

=item img_ids => 0

=item disable_tables => 1

=item disable_footnotes  => 1

=item disable_bibliography => 1

=back

=cut

sub new {
    my ($class, %p) = @_;

    %p = (%p, %force_opts);
    
    return $class->SUPER::new(%p);
}

=head2 markdown($text, $options)

Processes $text as markdown text and returns HTML. Takes an optional hashref of arguments, as per the
new method.

=cut

sub markdown {
    my ( $self, $text, $options ) = @_;

    # Detect functional mode, and create an instance for this run..
    unless (ref $self) {
        if ( $self ne __PACKAGE__ ) {
            my $ob = __PACKAGE__->new();
                                # $self is text, $text is options
            return $ob->markdown($self, $text);
        }
        else {
            croak('Calling ' . $self . '->markdown (as a class method) is not supported.');
        }
    }

    $options ||= {};
    %{ $options } = (%$options, %force_opts);
    return $self->SUPER::markdown($text, $options);
}

1;

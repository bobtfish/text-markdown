package Text::MultiMarkdown;
require 5.008_000;
use strict;
use warnings;
use re 'eval';

use Digest::MD5 qw(md5_hex);
use Encode      qw();
use Carp        qw(croak);
use base        qw(Text::Markdown);

our $VERSION   = '1.0.24';
our @EXPORT_OK = qw(markdown);

=head1 NAME

Text::MultiMarkdown - Convert MultiMarkdown syntax to (X)HTML

=head1 SYNOPSIS

    use Text::MultiMarkdown 'markdown';
    my $html = markdown($text);

    use Text::MultiMarkdown 'markdown';
    my $html = markdown( $text, {
        empty_element_suffix => '>',
        tab_width => 2,
        use_wikilinks => 1,
    } );

    use Text::MultiMarkdown;
    my $m = Text::MultiMarkdown->new;
    my $html = $m->markdown($text);

    use Text::MultiMarkdown;
    my $m = Text::MultiMarkdown->new(
        empty_element_suffix => '>',
        tab_width => 2,
        use_wikilinks => 1,
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

This module implements the MultiMarkdown markdown syntax extensions from:

    http://fletcherpenney.net/multimarkdown/

=head1 SYNTAX

For more information about (original) Markdown's syntax, see:

    http://daringfireball.net/projects/markdown/
    
This module implements MultiMarkdown, which is an extension to Markdown..

The extension is documented at:

    http://fletcherpenney.net/multimarkdown/

and borrows from php-markdown, which lives at:

    http://michelf.com/projects/php-markdown/extra/

This documentation is going to be moved/copied into this module for clearer reading in a future release..

=head1 OPTIONS

MultiMarkdown supports a number of options to it's processor which control the behaviour of the output document.

These options can be supplied to the constructor, on in a hash with the individual calls to the markdown method.
See the synopsis for examples of both of the above styles.

The options for the processor are:

=over

=item use_metadata

Controls the metadata options below.

=item strip_metadata

If true, any metadata in the input document is removed from the output document (note - does not take effect in complete document format).

=item empty element suffix

This option can be used to generate normal HTML output. By default, it is ' />', which is xHTML, change to '>' for normal HTML.

=item img_ids

Controls if <img> tags generated have an id attribute. Defaults to true. 
Turn off for compatibility with the original markdown.

=item heading_ids

Controls if <hX> tags generated have an id attribute. Defaults to true. 
Turn off for compatibility with the original markdown.

=item bibliography_title

The title of the generated bibliography, defaults to 'Bibliography'.

=item tab_width

Controls indent width in the generated markup, defaults to 4

=item markdown_in_html_blocks

Controls if Markdown is processed when inside HTML blocks. Defaults to 0.

=item disable_tables

If true, this disables the MultiMarkdown table handling.

=item disable_footnotes

If true, this disables the MultiMarkdown footnotes handling.

=item disable_bibliography

If true, this disables the MultiMarkdown bibliography/citation handling.

=back

A number of possible items of metadata can also be supplied as options. 
Note that if the use_metadata is true then the metadata in the document will overwrite the settings on command line.

Metadata options supported are:

=over

=item document_format

=item use_wikilinks

=item base_url

=back

=head1 METADATA

MultiMarkdown supports the concept of 'metadata', which allows you to specify a number of formatting options
within the document itself. Metadata should be placed in the top few lines of a file, on value per line as colon separated key/value pairs.
The metadata should be separated from the document with a blank line.

Most metadata keys are also supported as options to the constructor, or options
to the markdown method itself. (Note, as metadata, keys contain space, whereas options the keys are underscore separated.)

You can attach arbitrary metadata to a document, which is output in HTML <META> tags if unknown, see t/11document_format.t for more info.

A list of 'known' metadata keys, and their effects are listed below:

=over

=item document format

If set to 'complete', MultiMarkdown will render an entire xHTML page, otherwise it will render a document fragment

=over

=item css

Sets a CSS file for the file, if in 'complete' document format.

=item title

Sets the page title, if in 'complete' document format.

=back

=item use wikilinks

If set to '1' or 'on', causes links that are WikiWords to automatically be processed into links.

=item base url

This is the base URL for referencing wiki pages. In this is not supplied, all wiki links are relative.

=back

=head1 METHODS

=head2 new

A simple constructor, see the SYNTAX and OPTIONS sections for more information.

=cut

sub new {
    my ($class, %p) = @_;
    
    # Default metadata to 1
    $p{use_metadata} = 1 unless exists $p{use_metadata};
    # Squash value to [01]
    $p{use_metadata} = $p{use_metadata} ? 1 : 0;
    
    $p{base_url} ||= ''; # This is the base url to be used for WikiLinks
    
    $p{tab_width} = 4 unless (defined $p{tab_width} and $p{tab_width} =~ m/^\d+$/);
    
    $p{document_format} ||= '';
    
    $p{empty_element_suffix} ||= ' />'; # Change to ">" for HTML output
    
    #$p{heading_ids} = defined $p{heading_ids} ? $p{heading_ids} : 1;
    
    # For use with WikiWords and [[Wiki Links]]
    # NOTE: You can use \WikiWord to prevent a WikiWord from being treated as a link
    $p{use_wikilinks} = $p{use_wikilinks} ? 1 : 0;
    
    # Is markdown processed in HTML blocks? See t/15inlinehtmldonotturnoffmarkdown.t
    $p{markdown_in_html_blocks} = $p{markdown_in_html_blocks} ? 1 : 0;
    
    $p{heading_ids} = defined $p{heading_ids} ? $p{heading_ids} : 1;
    $p{img_ids}     = defined $p{img_ids}     ? $p{img_ids}     : 1;
    
    $p{bibliography_title} ||= 'Bibliography'; # FIXME - Test and document, can also be in metadata!
    
    my $self = { params => \%p };
    bless $self, ref($class) || $class;
    return $self;
}

=head2 markdown

The main function as far as the outside world is concerned. See the SYNOPSIS
for details on use.

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

    %$self = (%{ $self->{params} }, %$options, params => $self->{params});
    
    $self->_CleanUpRunData($options);
    
    return $self->_Markdown($text);
}

sub _CleanUpRunData {
    my ($self, $options) = @_;    
    # Clear the global hashes. If we don't clear these, you get conflicts
    # from other articles when generating a page which contains more than
    # one article (e.g. an index page that shows the N most recent
    # articles):
    $self->{_crossrefs}   = {};
    $self->{_footnotes}   = {};
    $self->{_references}  = {};
    $self->{_used_footnotes}  = []; # Why do we need 2 data structures for footnotes? FIXME
    $self->{_used_references} = []; # Ditto for references
    $self->{_citation_counter} = 0;
    $self->{_metadata} = {};
    $self->{_attributes}  = {}; # Used for extra attributes on links / images.
    
    $self->SUPER::_CleanUpRunData($options);
}

sub _Markdown {
#
# Main function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
# Can't think of any good way to make this inherit from the Markdown version as ordering is so important, so I've left it.
    my ($self, $text) = @_;
    
    $text = $self->_CleanUpDoc($text);
    
    # MMD only. Strip out MetaData
    $text = $self->_ParseMetaData($text) if ($self->{use_metadata} || $self->{strip_metadata});

    # Turn block-level HTML blocks into hash entries
    $text = $self->_HashHTMLBlocks($text) unless $self->{markdown_in_html_blocks};

    $text = $self->_StripLinkDefinitions($text);
    
    # MMD only
    $text = $self->_StripMarkdownReferences($text);

    $text = $self->_RunBlockGamut($text);
    
    # MMD Only
    $text = $self->_DoMarkdownCitations($text) unless $self->{disable_bibliography};
    $text = $self->_DoFootnotes($text) unless $self->{disable_footnotes};
    
    $text = $self->_UnescapeSpecialChars($text);

    # MMD Only
    # This must follow _UnescapeSpecialChars
    $text = $self->_UnescapeWikiWords($text);
    $text = $self->_FixFootnoteParagraphs($text) unless $self->{disable_footnotes};
    $text .= $self->_PrintFootnotes() unless $self->{disable_footnotes};
    $text .= $self->_PrintMarkdownBibliography() unless $self->{disable_bibliography};
        
    $text = $self->_ConvertCopyright($text);

    # MMD Only
    if (lc($self->{document_format}) =~ /^complete\s*$/) {
        return $self->_xhtmlMetaData() . "<body>\n" . $text . "\n</body>\n</html>";
    } 
    else {
        return $self->_textMetaData() . $text . "\n";
    }
    
}

#
# Routines which are overridden for slightly different behaviour in MultiMarkdown
#

# Delegate to super class, then do wiki links
sub _RunSpanGamut {
    my ($self, $text) = @_;

    $text = $self->SUPER::_RunSpanGamut($text);
    
    # Process WikiWords
    if ($self->_UseWikiLinks()) {
        $text = $self->_DoWikiLinks($text);
        
        # And then reprocess anchors and images
        # FIXME - This is needed exactly why?
        $text = $self->_DoImages($text);
        $text = $self->_DoAnchors($text);
    }
    
    return $text;
}

# Don't do Wiki Links in Headers, otherwise delegate to super class
# Do tables stright after headers
sub _DoHeaders {
    my ($self, $text) = @_;

    local $self->{use_wikilinks} = 0;
    
    $text = $self->SUPER::_DoHeaders($text);
    
    # Do tables to populate the table id's for cross-refs
    # (but after headers as the tables can contain cross-refs to other things, so we want the header cross-refs)
    $text = $self->_DoTables($text);
}

# Generating headers automatically generates X-refs in MultiMarkdown (always)
# Also, by default, you get id attributes added to your headers, you can turn this
# part of the MultiMarkdown behaviour off with the heading_ids flag.
sub _GenerateHeader {
    my ($self, $level, $id) = @_;
    
    my $label = $self->{heading_ids} ? $self->_Header2Label($id) : '';
    my $header = $self->_RunSpanGamut($id);
    
    if ($label ne '') {
        $self->{_crossrefs}{$label} = "#$label";
        $self->{_titles}{$label} = $header;
        $label = qq{ id="$label"};
    }
    
    return "<h$level$label>$header</h$level>\n\n";
}

# Protect Wiki Links in Code Blocks (if wiki links are turned on), then delegate to super class.
sub _EncodeCode {
    my ($self, $text) = @_;

    if ($self->_UseWikiLinks()) {
        $text =~ s/([A-Z]+[a-z\x80-\xff]+[A-Z][A-Za-z\x80-\xff]*)/\\$1/gx;
    }
    
    return $self->SUPER::_EncodeCode($text);
}

# Full function pulled out of Text::Markdown as MultiMarkdown supports supplying extra 'attributes' with links and
#  images which are then pushed back into the generated HTML, and this needs a different regex. It should be possible
#  to extract the just the regex from Text::Markdown, and use that here, but I haven't done so yet.
# Strip footnote definitions at the same time as stripping link definitions.
# Also extract images and then replace them straight back in (code smell!) to be able to cross reference images
sub _StripLinkDefinitions {
#
# Strips link definitions from text, stores the URLs and titles in
# hash references.
#
    my ($self, $text) = @_;
    
    $text = $self->_StripFootnoteDefinitions($text) unless $self->{disable_footnotes};
    
    my $less_than_tab = $self->{tab_width} - 1;

    # Link defs are in the form: ^[id]: url "optional title"
    # FIXME - document attributes here.
    while ($text =~ s{
	                	# Pattern altered for MultiMarkdown
                		# in order to not match citations or footnotes
                		^[ ]{0,$less_than_tab}\[([^#^].*)\]:	# id = $1
                		  [ \t]*
                		  \n?				# maybe *one* newline
                		  [ \t]*
                		<?(\S+?)>?			# url = $2
                		  [ \t]*
                		  \n?				# maybe one newline
                		  [ \t]*
                		(?:
                			(?<=\s)			# lookbehind for whitespace
                			["(]
                			(.+?)			# title = $3
                			[")]
                			[ \t]*
                		)?	# title is optional
		
                		# MultiMarkdown addition for attribute support
                		\n?
                		(				# Attributes = $4
                			(?<=\s)			# lookbehind for whitespace
                			(([ \t]*\n)?[ \t]*((\S+=\S+)|(\S+=".*?")))*
                		)?
                		[ \t]*
                		# /addition
                		(?:\n+|\Z)
                    }
                    {}mx) {
        $self->{_urls}{lc $1} = $self->_EncodeAmpsAndAngles( $2 );    # Link IDs are case-insensitive
        if ($3) {
            $self->{_titles}{lc $1} = $3;
            $self->{_titles}{lc $1} =~ s/"/&quot;/g;
        }
        
        # MultiMarkdown addition "
        if ($4) {
            $self->{_attributes}{lc $1} = $4;
        }
        # /addition
    }

    $text = $self->_GenerateImageCrossRefs($text);

    return $text;
}

# Add the extra cross-references to headers that MultiMarkdown supports, and also
# the additional link attributes.
sub _GenerateAnchor {
    # FIXME - Fugly, change to named params?
    my ($self, $whole_match, $link_text, $link_id, $url, $title, $attributes) = @_;

    # Allow automatic cross-references to headers
    if (defined $link_id) {
        my $label = $self->_Header2Label($link_id);
        if (defined $self->{_crossrefs}{$label}) {
            $url ||= $self->{_crossrefs}{$label};
        }
        if ( defined $self->{_titles}{$label} ) {
            $title ||= $self->{_titles}{$label};
        }
        $attributes ||= $self->_DoAttributes($label);
    }
    return $self->SUPER::_GenerateAnchor($whole_match, $link_text, $link_id, $url, $title, $attributes);
}

# Add the extra cross-references to images that MultiMarkdown supports, and also
# the additional attributes.
sub _GenerateImage {
    # FIXME - Fugly, change to named params?
    my ($self, $whole_match, $alt_text, $link_id, $url, $title, $attributes) = @_;
    
    if (defined $alt_text && length $alt_text) {
        my $label = $self->_Header2Label($alt_text);
        $self->{_crossrefs}{$label} = "#$label";
        $attributes .= $self->{img_ids} ? qq{ id="$label"} : '';
    }
    
    $attributes .= $self->_DoAttributes($link_id) if defined $link_id;
    
    $self->SUPER::_GenerateImage($whole_match, $alt_text, $link_id, $url, $title, $attributes);
}


#
# MultiMarkdown specific routines
#

# FIXME - This is really really ugly!
sub _ParseMetaData { 
    my ($self, $text) = @_;
    my $clean_text = "";
    
    my ($inMetaData, $currentKey) = (1, '');
    
    foreach my $line ( split /\n/, $text ) {
        $line =~ /^\s*$/ and $inMetaData = 0 and $clean_text .= $line and next;
        if ($inMetaData) {
            next unless $self->{use_metadata}; # We can come in here as use_metadata => 0, strip_metadata => 1
            if ($line =~ /^([a-zA-Z0-9][0-9a-zA-Z _-]+?):\s*(.*)$/ ) {
                $currentKey = $1;
                $currentKey =~ s/  / /g;
                $self->{_metadata}{$currentKey} = defined $2 ? $2 : '';
                if (lc($currentKey) eq "format") {
                    $self->{document_format} = $self->{_metadata}{$currentKey};
                }
                if (lc($currentKey) eq "base url") {
                    $self->{base_url} = $self->{_metadata}{$currentKey};
                }
                if (lc($currentKey) eq "bibliography title") {
                    $self->{bibliography_title} = $self->{_metadata}{$currentKey};
                    $self->{bibliography_title} =~ s/\s*$//;
                }
            } 
            else {
                if ($currentKey eq "") {
                    # No metadata present
                    $clean_text .= "$line\n";
                    $inMetaData = 0;
                    next;
                }
                if ($line =~ /^\s*(.+)$/ ) {
                    $self->{_metadata}{$currentKey} .= "\n$1";
                }
            }
        } 
        else {
            $clean_text .= "$line\n";
        }
    }
    
    # Recheck for leading blank lines
    $clean_text =~ s/^\n+//s;
        
    return $clean_text;
}

# FIXME - This is really ugly, why do we match stuff and substitute it with the thing we just matched?
sub _GenerateImageCrossRefs {
    my ($self, $text) = @_;

    #
    # First, handle reference-style labeled images: ![alt text][id]
    #
    $text =~ s{
        (               # wrap whole match in $1
          !\[
            (.*?)       # alt text = $2
          \]

          [ ]?              # one optional space
          (?:\n[ ]*)?       # one optional newline followed by spaces

          \[
            (.*?)       # id = $3
          \]

        )
    }{
        my $whole_match = $1;
        my $alt_text    = $2;
        my $link_id     = lc $3;

        if ($link_id eq "") {
            $link_id = lc $alt_text;     # for shortcut links like ![this][].
        }

        $alt_text =~ s/"/&quot;/g;
        
        if (defined $self->{_urls}{$link_id}) {
            my $label = $self->_Header2Label($alt_text);
            $self->{_crossrefs}{$label} = "#$label";
        }

        $whole_match;
    }xsge;

    #
    # Next, handle inline images:  ![alt text](url "optional title")
    # Don't forget: encode * and _

    $text =~ s{
        (               # wrap whole match in $1
          !\[
            (.*?)       # alt text = $2
          \]
          \(            # literal paren
            [ \t]*
            <?(\S+?)>?  # src url = $3
            [ \t]*
            (           # $4
              (['"])    # quote char = $5
              (.*?)     # title = $6
              \5        # matching quote
              [ \t]*
            )?          # title is optional
          \)
        )
    }{
        my $result;
        my $whole_match = $1;
        my $alt_text    = $2;

        $alt_text =~ s/"/&quot;/g;
        my $label = $self->_Header2Label($alt_text);
        $self->{_crossrefs}{$label} = "#$label";
        $whole_match;
    }xsge;

    return $text;
}

sub _StripFootnoteDefinitions {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;
    
    while ($text =~ s{
	  \n\[\^([^\n]+?)\]\:[ \t]*# id = $1
	  \n?
	  (.*?)\n{1,2}		# end at new paragraph
	  ((?=\n[ ]{0,$less_than_tab}\S)|\Z)	# Lookahead for non-space at line-start, or end of doc
    }
    {\n}sx)
    {
        my $id = $1;
        my $footnote = "$2\n";
        $footnote =~ s/^[ ]{0,$self->{tab_width}}//gm;
    
        $self->{_footnotes}{$self->_Id2Footnote($id)} = $footnote;
    }
    
    return $text;
}

sub _DoFootnotes {
    my ($self, $text) = @_;
    
    return '' unless length $text;
    
    # First, run routines that get skipped in footnotes
    foreach my $label (sort keys %{ $self->{_footnotes} }) {
        my $footnote = $self->_RunBlockGamut($self->{_footnotes}{$label});

        $footnote = $self->_DoMarkdownCitations($footnote);
        $self->{_footnotes}{$label} = $footnote;
    }
    
    my $footnote_counter = 0;
        
    $text =~ s{
        \[\^(.*?)\]     # id = $1
    }{
        my $result = '';
        my $id = $self->_Id2Footnote($1);
        
        if (defined $self->{_footnotes}{$id} ) {
            $footnote_counter++;
            if ($self->{_footnotes}{$id} =~ /^glossary:/i) {
                $result = qq{<a href="#fn:$id" id="fnref:$id" class="footnote glossary">$footnote_counter</a>};
            } 
            else {
                $result = qq{<a href="#fn:$id" id="fnref:$id" class="footnote">$footnote_counter</a>};
            }
            push (@{ $self->{_used_footnotes} }, $id);
        }
        $result;
    }xsge;
    
    return $text;
}

sub _FixFootnoteParagraphs {
    my ($self, $text) = @_;
    
    $text =~ s/^\<p\>\<\/footnote\>/<\/footnote>/gm;
    
    return $text;
}

sub _PrintFootnotes {
    my ($self) = @_;
    my $footnote_counter = 0;
    my $result;
    
    foreach my $id (@{ $self->{_used_footnotes} }) {
        $footnote_counter++;
        my $footnote = $self->{_footnotes}{$id};
        my $footnote_closing_tag = '';
 
        $footnote =~ s/(\<\/(p(re)?|ol|ul)\>)$//;
        $footnote_closing_tag = $1;
        
        if ($footnote =~ s/^glossary:\s*//i) {
            # Add some formatting for glossary entries
 
            $footnote =~ s{
                ^(.*?)              # $1 = term
                \s*
                (?:\(([^\(\)]*)\)[^\n]*)?       # $2 = optional sort key
                \n
            }{
                my $glossary = qq{<span class="glossary name">$1</span>};
                
                if ($2) {
                    $glossary.= qq{<span class="glossary sort" style="display:none">$2</span>};
                };
                
                $glossary . q{:<p>}; 
            }egsx;
 
            $result .= qq{<li id="fn:$id">$footnote<a href="#fnref:$id" class="reversefootnote">&#160;&#8617;</a>$footnote_closing_tag</li>\n\n};
        } 
        else {
            $result .= qq{<li id="fn:$id">$footnote<a href="#fnref:$id" class="reversefootnote">&#160;&#8617;</a>$footnote_closing_tag</li>\n\n};
        }
    }

    if ($footnote_counter > 0) {
        $result = qq[\n\n<div class="footnotes">\n<hr$self->{empty_element_suffix}\n<ol>\n\n] . $result . "</ol>\n</div>";
    } 
    else {
        $result = "";
    }   
    
    return $result;
}

sub _Header2Label {
    my ($self, $header) = @_;
    my $label = lc $header;
    $label =~ s/[^A-Za-z0-9:_.-]//g;        # Strip illegal characters
    while ($label =~ s/^[^A-Za-z]//g)
        {};     # Strip illegal leading characters
    return $label;
}

sub _Id2Footnote {
    # Since we prepend "fn:", we can allow leading digits in footnotes
    my ($self, $id) = @_;
    my $footnote = lc $id;
    $footnote =~ s/[^A-Za-z0-9:_.-]//g;     # Strip illegal characters
    return $footnote;
}

sub _xhtmlMetaData {
    my ($self) = @_;
    # FIXME: Should not assume encoding
    my $result; # FIXME: This breaks some things in IE 6- = qq{<?xml version="1.0" encoding="UTF-8" ?>\n};

    # This screws up xsltproc - make sure to use `-nonet -novalid` if you
    #   have difficulty
    $result .= qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n};

    $result.= "<html>\n\t<head>\n";
    
    foreach my $key (sort keys %{$self->{_metadata}} ) {
        if (lc($key) eq "title") {
            $result.= "\t\t<title>$self->{_metadata}{$key}</title>\n";
        } 
        elsif (lc($key) eq "css") {
            $result.= qq[\t\t<link type="text/css" rel="stylesheet" href="$self->{_metadata}{$key}"$self->{empty_element_suffix}\n];
        } 
        else {
            $result.= qq[\t\t<meta name="$key" content="$self->{_metadata}{$key}"$self->{empty_element_suffix}\n];
        }
    }
    $result.= "\t</head>\n";
    
    return $result;
}

sub _textMetaData {
    my ($self) = @_;
    my $result = "";
    
    return $result if $self->{strip_metadata};

    foreach my $key (sort keys %{$self->{_metadata}} ) {
        $result .= "$key: $self->{_metadata}{$key}\n";
    }
    $result =~ s/\s*\n/<br$self->{empty_element_suffix}\n/g;
    
    if ($result ne "") {
        $result.= "\n";
    }
    
    return $result;
}

sub _UseWikiLinks {
    my ($self) = @_;
    return 1 if $self->{use_wikilinks};
    my ($k) = grep { /use wikilinks/i } keys %{$self->{_metadata}};
    return unless $k;
    return 1 if $self->{_metadata}{$k};
    return;
}

sub _CreateWikiLink {
    my ($self, $title) = @_;
    
    my $id = $title;
        $id =~ s/ /_/g;
        $id =~ s/__+/_/g;
        $id =~ s/^_//g;
        $id =~ s/_$//;

    $title =~ s/_/ /g;
    
    return "[$title](" . $self->{base_url} . "$id)";
}

sub _DoWikiLinks {
    
    my ($self, $text) = @_;
    my $WikiWord = '[A-Z]+[a-z\x80-\xff]+[A-Z][A-Za-z\x80-\xff]*';
    my $FreeLinkPattern = "([-,.()' _0-9A-Za-z\x80-\xff]+)";
    
    if ($self->_UseWikiLinks()) {
        # FreeLinks
        $text =~ s{
            \[\[($FreeLinkPattern)\]\]
        }{
            my $label = $1;
            $label =~ s{
                ([\s\>])($WikiWord)
            }{
                $1 ."\\" . $2
            }xsge;
            
            $self->_CreateWikiLink($label)
        }xsge;
    
        # WikiWords
        $text =~ s{
            ([\s])($WikiWord)
        }{
            $1 . $self->_CreateWikiLink($2)
        }xsge;
        
        # Catch WikiWords at beginning of text
        $text =~ s{^($WikiWord)
        }{
            $self->_CreateWikiLink($1)
        }xse;
    }
    
    
    return $text;
}

sub _UnescapeWikiWords {
    my ($self, $text) = @_;
    my $WikiWord = '[A-Z]+[a-z\x80-\xff]+[A-Z][A-Za-z\x80-\xff]*';
    
    # Unescape escaped WikiWords
    $text =~ s/(?<=\B)\\($WikiWord)/$1/g;

    return $text;
}

sub _DoTables {
    my ($self, $text) = @_;
    
    return $text if $self->{disable_tables};
    
    my $less_than_tab = $self->{tab_width} - 1;

    # Algorithm inspired by PHP Markdown Extra's
    # <http://www.michelf.com/projects/php-markdown/>
        
    # Reusable regexp's to match table
    
    my $line_start = qr{
        [ ]{0,$less_than_tab}
    }mx;
    
    my $table_row = qr{
        [^\n]*?\|[^\n]*?\n
    }mx;
        
    my $first_row = qr{
        $line_start
        \S+.*?\|.*?\n
    }mx;
    
    my $table_rows = qr{
        (\n?$table_row)
    }mx;
    
    my $table_caption = qr{
        $line_start
        \[.*?\][ \t]*\n
    }mx;
    
    my $table_divider = qr{
        $line_start
        [\|\-\:\.][ \-\|\:\.]* \| [ \-\|\:\.]* 
    }mx;
    
    my $whole_table = qr{
        ($table_caption)?       # Optional caption
        ($first_row             # First line must start at beginning
        ($table_row)*?)?        # Header Rows
        $table_divider          # Divider/Alignment definitions
        $table_rows+            # Body Rows
        ($table_caption)?       # Optional caption
    }mx;
    
    
    # Find whole tables, then break them up and process them
    
    $text =~ s{
        ^($whole_table)         # Whole table in $1
        (\n|\Z)                 # End of file or 2 blank lines
    }{
        my $table = $1;
        my $result = "<table>\n";
        my @alignments;
        my $use_row_header = 0;
        
        # Add Caption, if present
        
        if ($table =~ s/^$line_start\[\s*(.*?)\s*\](\[\s*(.*?)\s*\])?[ \t]*$//m) {
            if (defined $3) {
                # add caption id to cross-ref list
                my $table_id = $self->_Header2Label($3);
                $result .= qq{<caption id="$table_id">} . $self->_RunSpanGamut($1). "</caption>\n";
                
                $self->{_crossrefs}{$table_id} = "#$table_id";
                $self->{_titles}{$table_id} = "$1";
            } 
            else {
                $result .= "<caption>" . $self->_RunSpanGamut($1). "</caption>\n";
            }
        }
                
        # If a second "caption" is present, treat it as a summary
        # However, this is not valid in XHTML 1.0 Strict
        # But maybe in future
        
        # A summary might be longer than one line
        if ($table =~ s/\n$line_start\[\s*(.*?)\s*\][ \t]*\n/\n/s) {
            # $result .= "<summary>" . $self->_RunSpanGamut($1) . "</summary>\n";
        }
        
        # Now, divide table into header, alignment, and body

        # First, add leading \n in case there is no header
        
        $table = "\n" . $table;
        
        # Need to be greedy
        
        $table =~ s/\n($table_divider)\n(($table_rows)+)//s;

        my $alignment_string = $1;
        my $body = $2;
        
        # Process column alignment
        while ($alignment_string =~ /\|?\s*(.+?)\s*(\||\Z)/gs) {
            my $cell = $self->_RunSpanGamut($1);
            if ($cell =~ /\:$/) {
                if ($cell =~ /^\:/) {
                    $result .= qq[<col align="center"$self->{empty_element_suffix}\n];
                    push(@alignments,"center");
                } 
                else {
                    $result .= qq[<col align="right"$self->{empty_element_suffix}\n];
                    push(@alignments,"right");
                }
            } 
            else {
                if ($cell =~ /^\:/) {
                    $result .= qq[<col align="left"$self->{empty_element_suffix}\n];
                    push(@alignments,"left");
                } 
                else {
                    if (($cell =~ /^\./) || ($cell =~ /\.$/)) {
                        $result .= qq[<col align="char"$self->{empty_element_suffix}\n];
                        push(@alignments,"char");
                    } 
                    else {
                        $result .= "<col$self->{empty_element_suffix}\n";
                        push(@alignments,"");
                    }
                }
            }
        }
        
        # Process headers
        $table =~ s/^\n+//s;
        
        $result .= "<thead>\n";
        
        # Strip blank lines
        $table =~ s/\n[ \t]*\n/\n/g;
        
        foreach my $line (split(/\n/, $table)) {
            # process each line (row) in table
            $result .= "<tr>\n";
            my $count=0;
            while ($line =~ /\|?\s*([^\|]+?)\s*(\|+|\Z)/gs) {
                # process contents of each cell
                my $cell = $self->_RunSpanGamut($1);
                my $ending = $2;
                my $colspan = "";
                if ($ending =~ s/^\s*(\|{2,})\s*$/$1/) {
                    $colspan = " colspan=\"" . length($ending) . "\"";
                }
                $result .= "\t<th$colspan>$cell</th>\n";
                if ( $count == 0) {
                    if ($cell =~ /^\s*$/) {
                        $use_row_header = 1;
                    } 
                    else {
                        $use_row_header = 0;
                    }
                }
                $count++;
            }
            $result .= "</tr>\n";
        }
        
        # Process body
        
        $result .= "</thead>\n<tbody>\n";

        foreach my $line (split(/\n/, $body)) {
            # process each line (row) in table
            if ($line =~ /^\s*$/) {
                $result .= "</tbody>\n\n<tbody>\n";
                next;
            }
            $result .= "<tr>\n";
            my $count=0;
            while ($line =~ /\|?\s*([^\|]+?)\s*(\|+|\Z)/gs) {
                # process contents of each cell
                no warnings 'uninitialized';
                my $cell = $self->_RunSpanGamut($1);
                my $ending = $2;
                my $colspan = "";
                my $cell_type = "td";
                if ($count == 0 && $use_row_header == 1) {
                    $cell_type = "th";
                }
                if ($ending =~ s/^\s*(\|{2,})\s*$/$1/) {
                    $colspan = " colspan=\"" . length($ending) . "\"";
                }
                if ($alignments[$count] !~ /^\s*$/) {
                    $result .= "\t<$cell_type$colspan align=\"$alignments[$count]\">$cell</$cell_type>\n";
                } 
                else {
                    $result .= "\t<$cell_type$colspan>$cell</$cell_type>\n";
                }
                $count++;
            }
            $result .= "</tr>\n";
        }

        $result .= "</tbody>\n</table>\n";
        $result
    }egmx;
    
    my $table_body = qr{
        (                               # wrap whole match in $2
            
            (.*?\|.*?)\n                    # wrap headers in $3
            
            [ ]{0,$less_than_tab}
            ($table_divider)    # alignment in $4
            
            (                           # wrap cells in $5
                $table_rows
            )
        )
    }mx;
    
    return $text;
}

sub _DoAttributes {
    my ($self, $id) = @_;
    my $result = "";
    
    if (defined $self->{_attributes}{$id}) {
        while ($self->{_attributes}{$id} =~ s/(\S+)="(.*?)"//) {
            $result .= qq{ $1="$2"};
        }
        while ($self->{_attributes}{$id} =~ /(\S+)=(\S+)/g) {
            $result .= qq{ $1="$2"};
        }
    }
    
    return $result;
}

sub _StripMarkdownReferences {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;

    while ($text =~ s{
        \n\[\#(.+?)\]:[ \t]*    # id = $1
        \n?
        (.*?)\n{1,2}            # end at new paragraph
        ((?=\n[ ]{0,$less_than_tab}\S)|\Z)  # Lookahead for non-space at line-start, or end of doc
    }
    {\n}sx)
    {
        my $id = $1;
        my $reference = "$2\n";

        $reference =~ s/^[ ]{0,$self->{tab_width}}//gm;
        
        $reference = $self->_RunBlockGamut($reference);

        # strip leading and trailing <p> tags (they will be added later)
        $reference =~ s/^\<p\>//s;
        $reference =~ s/\<\/p\>\s*$//s;
        
        $self->{_references}{$id} = $reference;
    }
    
    return $text;
}

sub _DoMarkdownCitations {
    my ($self, $text) = @_;
    
    $text =~ s{
        \[([^\[]*?)\]       # citation text = $1
        [ ]?            # one optional space
        (?:\n[ ]*)?     # one optional newline followed by spaces
        \[\#(.*?)\]     # id = $2
    }{
        my $result;
        my $anchor_text = $1;
        my $id = $2;
        my $count;
        
        if (defined $self->{_references}{$id} ) {
            my $citation_counter=0;
            
            # See if citation has been used before
            foreach my $old_id (@{ $self->{_used_references} }) {
                $citation_counter++;
                $count = $citation_counter if ($old_id eq $id);
            }
    
            if (! defined $count) {
                $count = ++$self->{_citation_counter};
                push (@{ $self->{_used_references} }, $id);
            }
            
            $result = qq[<span class="markdowncitation"> (<a href="#$id">$count</a>];
            
            if ($anchor_text ne "") {
                $result .= qq[, <span class="locator">$anchor_text</span>];
            }
            
            $result .= ")</span>";
        } 
        else {
            # No reference exists
            $result = qq[<span class="externalcitation"> (<a id="$id">$id</a>];

            if ($anchor_text ne "") {
                $result .= qq[, <span class="locator">$anchor_text</span>];
            }
            
            $result .= ")</span>";
        }
        
        if ($self->_Header2Label($anchor_text) eq "notcited"){
            $result = qq[<span class="notcited" id="$id"/>];
        }
        $result;
    }xsge;
    
    return $text;
}

sub _PrintMarkdownBibliography {
    my ($self) = @_;
    my $citation_counter = 0;
    my $result;
    
    foreach my $id (@{ $self->{_used_references} }) {
        $citation_counter++;
        $result .= qq|<div id="$id"><p>[$citation_counter] <span class="item">$self->{_references}{$id}</span></p></div>\n\n|;
    }
    $result .= "</div>";

    if ($citation_counter > 0) {
        $result = qq[\n\n<div class="bibliography">\n<hr$self->{empty_element_suffix}\n<p>$self->{bibliography_title}</p>\n\n] . $result;
    } 
    else {
        $result = "";
    }   
    
    return $result;
}

1;

__END__

=head1 BUGS

To file bug reports or feature requests please send email to:

    bug-Text-Markdown@rt.cpan.org
    
Please include with your report: (1) the example input; (2) the output
you expected; (3) the output Markdown actually produced.

=head1 VERSION HISTORY

See the Changes file for detailed release notes for this version.

=head1 AUTHOR

    John Gruber
    http://daringfireball.net/

    PHP port and other contributions by Michel Fortin
    http://michelf.com/

    MultiMarkdown changes by Fletcher Penney
    http://fletcher.freeshell.org/

    CPAN Module Text::MultiMarkdown (based on Text::Markdown by Sebastian
    Riedel) originally by Darren Kulp (http://kulp.ch/)
    
    This module is maintained by: Tomas Doran http://www.bobtfish.net/

=head1 THIS DISTRIBUTION

Please note that this distribution is a fork of Fletcher Penny's MultiMarkdown project, 
and it *is not* in any way blessed by him.

Whilst this code aims to be compatible with the original MultiMarkdown (and incorporates 
and passes the MultiMarkdown test suite) whilst fixing a number of bugs in the original - 
there may be differences between the behaviour of this module and MultiMarkdown. If you find
any differences where you believe Text::MultiMarkdown behaves contrary to the MultiMarkdown spec, 
please report them as bugs.

Text::Markdown *does not* extend the markdown dialect in any way from that which is documented at
daringfireball. If you want additional features, you should look at L<Text::MultiMarkdown>.

=head1 COPYRIGHT AND LICENSE

Original Code Copyright (c) 2003-2004 John Gruber   
<http://daringfireball.net/>   
All rights reserved.

MultiMarkdown changes Copyright (c) 2005-2006 Fletcher T. Penney   
<http://fletcher.freeshell.org/>   
All rights reserved.

Text::MultiMarkdown changes Copyright (c) 2006-2008 Darren Kulp
<http://kulp.ch> and Tomas Doran <http://www.bobtfish.net>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name "Markdown" nor the names of its contributors may
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

=cut

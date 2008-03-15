package Text::MultiMarkdown;
require 5.008_000;
use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use Encode      qw();
use Carp        qw(croak);
use base        'Exporter';

our $VERSION   = '1.0.16';
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

L<http://fletcherpenney.net/MultiMarkdown/>

=head1 SYNTAX

For more information about (original) Markdown's syntax, see:

    http://daringfireball.net/projects/markdown/
    
This module implements MultiMarkdown, which is an extension to Markdown..

The extension is documented at:

    http://fletcherpenney.net/MultiMarkdown/

and borrows from php-markdown, which lives at:

    http://michelf.com/projects/php-markdown/extra/

This documentation is going to be moved/copied into this module for clearer reading in a future release..

=head1 OPTIONS

MultiMarkdown supports a number of options to it's processor which control the behavior of the output document.

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

=cut

# Regex to match balanced [brackets]. See Friedl's
# "Mastering Regular Expressions", 2nd Ed., pp. 328-331.
my ($g_nested_brackets, $g_nested_parens); 
$g_nested_brackets = qr{
    (?>                                 # Atomic matching
       [^\[\]]+                         # Anything other than brackets
     | 
       \[
         (??{ $g_nested_brackets })     # Recursive set of nested brackets
       \]
    )*
}x;
# Doesn't allow for whitespace, because we're using it to match URLs:
$g_nested_parens = qr{
	(?> 								# Atomic matching
	   [^()\s]+							# Anything other than parens or whitespace
	 | 
	   \(
		 (??{ $g_nested_parens })		# Recursive set of nested brackets
	   \)
	)*
}x;

# Table of hash values for escaped characters:
my %g_escape_table;
foreach my $char (split //, '\\`*_{}[]()>#+-.!') {
    $g_escape_table{$char} = md5_hex($char);
}

# Global hashes, used by various utility routines
# FIXME - to be moved into instance data!
my %g_metadata_newline = ();

# FIXME - If we're using metadata, newlines (in the metadata have to be \n). Make configurable.
$g_metadata_newline{default} = "\n";

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
    
    my $self = { %p };
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
    
    $self->{_metadata} = {};
        
    # Localise all of these settings, so that if they're frobbed by options here (or metadata later), the change will not persist.
    # FIXME - There should be a nicer way to do this...
    local $self->{use_wikilinks}            = exists $options->{use_wikilinks}          ? $options->{use_wikilinks}          : $self->{use_wikilinks};
    local $self->{empty_element_suffix}     = exists $options->{empty_element_suffix}   ? $options->{empty_element_suffix}   : $self->{empty_element_suffix};
    local $self->{document_format}          = exists $options->{document_format}        ? $options->{document_format}        : $self->{document_format};
    local $self->{use_metadata}             = exists $options->{use_metadata}           ? $options->{use_metadata}           : $self->{use_metadata};
    local $self->{strip_metadata}           = exists $options->{strip_metadata}         ? $options->{strip_metadata}         : $self->{strip_metadata};
    local $self->{markdown_in_html_blocks}  = exists $options->{markdown_in_html_blocks}? $options->{o}: $self->{markdown_in_html_blocks};
    local $self->{disable_tables}           = exists $options->{disable_tables}         ? $options->{disable_tables}         : $self->{disable_tables};
    local $self->{disable_footnotes}        = exists $options->{disable_footnotes}      ? $options->{disable_footnotes}      : $self->{disable_footnotesf};
    local $self->{disable_bibliography}     = exists $options->{disable_bibliography}   ? $options->{disable_bibliography}   : $self->{disable_bibliography};
    local $self->{tab_width}                = exists $options->{tab_width}              ? $options->{tab_width}              : $self->{tab_width};
    
    # Clear the global hashes. If we don't clear these, you get conflicts
    # from other articles when generating a page which contains more than
    # one article (e.g. an index page that shows the N most recent
    # articles):
    $self->{_urls}        = $options->{urls}        ? $options->{urls}        : {}; # FIXME - document and test passing this option.
    $self->{_titles}      = $options->{titles}      ? $options->{titles}      : {}; # FIXME - ditto
    $self->{_html_blocks} = $options->{html_blocks} ? $options->{html_blocks} : {}; # FIXME - ditto
    $self->{_crossrefs}   = {};
    $self->{_footnotes}   = {};
    $self->{_references}  = {};
    $self->{_attributes}  = {}; # What is this used for again?
    $self->{_used_footnotes}  = []; # Why do we need 2 data structures for footnotes? FIXME
    $self->{_used_references} = []; # Ditto for references
    $self->{_citation_counter} = 0;
    # Used to track when we're inside an ordered or unordered list
    # (see _ProcessListItems() for details)
    $self->{_list_level} = 0;

    my $t =  $self->_Markdown($text);

    return $t; 
}

sub _Markdown {
#
# Main function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
    my ($self, $text) = @_;

    # Standardize line endings:
    $text =~ s{\r\n}{\n}g;  # DOS to Unix
    $text =~ s{\r}{\n}g;    # Mac to Unix

    # Make sure $text ends with a couple of newlines:
    $text .= "\n\n";

    # Convert all tabs to spaces.
    $text = $self->_Detab($text);

    # Strip any lines consisting only of spaces and tabs.
    # This makes subsequent regexen easier to write, because we can
    # match consecutive blank lines with /\n+/ instead of something
    # contorted like /[ \t]*\n+/ .
    $text =~ s/^[ \t]+$//mg;
    
    # Strip out MetaData
    $text = $self->_ParseMetaData($text) if ($self->{use_metadata} || $self->{strip_metadata});

    # And recheck for leading blank lines
    $text =~ s/^\n+//s;

    # Turn block-level HTML blocks into hash entries
    $text = $self->_HashHTMLBlocks($text) unless $self->{markdown_in_html_blocks};

    # Strip link definitions, store in hashes.
    $text = $self->_StripFootnoteDefinitions($text) unless $self->{disable_footnotes};

    $text = $self->_StripLinkDefinitions($text);

    $self->_GenerateImageCrossRefs($text);
    
    $text = $self->_StripMarkdownReferences($text);

    $text = $self->_RunBlockGamut($text);
    
    $text = $self->_DoMarkdownCitations($text) unless $self->{disable_bibliography};
    
    $text = $self->_DoFootnotes($text) unless $self->{disable_footnotes};
    
    $text = $self->_UnescapeSpecialChars($text);

    # This must follow _UnescapeSpecialChars
    $text = $self->_UnescapeWikiWords($text);

    $text = $self->_FixFootnoteParagraphs($text) unless $self->{disable_footnotes};
    $text .= $self->_PrintFootnotes() unless $self->{disable_footnotes};
    
    $text .= $self->_PrintMarkdownBibliography() unless $self->{disable_bibliography};
        
    $text = $self->_ConvertCopyright($text);

    if (lc($self->{document_format}) =~ /^complete\s*$/) {
        return $self->_xhtmlMetaData() . "<body>\n" . $text . "\n</body>\n</html>";
    } 
    else {
        return $self->_textMetaData() . $text . "\n";
    }
    
}

sub _StripLinkDefinitions {
#
# Strips link definitions from text, stores the URLs and titles in
# hash references.
#
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;

    # Link defs are in the form: ^[id]: url "optional title"
    while ($text =~ s{
                        ^[ ]{0,$less_than_tab}\[(.+)\]: # id = $1
                          [ \t]*
                          \n?               # maybe *one* newline
                          [ \t]*
                        <?(\S+?)>?          # url = $2
                          [ \t]*
                          \n?               # maybe one newline
                          [ \t]*
                        (?:
                            (?<=\s)         # lookbehind for whitespace
                            ["(]
                            (.+?)           # title = $3
                            [")]
                            [ \t]*
                        )?  # title is optional
                        
                        # MultiMarkdown addition for attribute support
                        \n?
                        (               # Attributes = $4
                            (?<=\s)         # lookbehind for whitespace
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

    return $text;
}

sub _md5_utf8 {
   # Internal function used to safely MD5sum chunks of the input, which might be Unicode in Perl's internal representation.
   my $input = shift;
   return unless defined $input;
   if (Encode::is_utf8 $input) {
       return md5_hex(Encode::encode('utf8', $input));
    } 
    else {
        return md5_hex($input);
    }
}

my @block_tags = qw(
    	p           div       h1  h2 h3 h4 h5 h6  blockquote    pre         table  
		dl          ol        ul        script        noscript    form   
		fieldset    iframe    math      ins           del
);
my %block_tags = map { ($_, '</' . $_ . '>') } @block_tags;

sub _HashHTMLBlocks {
    my ($self, $text) = @_;
    #warn ("In _HashHTMLBlocks for text {$text}");
    my $less_than_tab = $self->{tab_width} - 1;

	# Hashify HTML blocks:
	# We only want to do this for block-level HTML tags, such as headers,
	# lists, and tables. That's because we still want to wrap <p>s around
	# "paragraphs" that are wrapped in non-block-level tags, such as anchors,
	# phrase emphasis, and spans. The list of tags we're looking for is
	# hard-coded (see @block_tags above)

    my $tokens = $self->_TokenizeHTML($text);
	$text = '';   # rebuild $text from the tokens

    my $care = 1;
    my $lspace = 0;
    my @collected = (); # Would probably be faster to keep indexes, then slice them here.
    my @output = ();
    my $current_block_tag;
    my $current_block_end_tag;
    my $nesting_level = 0;
    
    use Data::Dumper;
    foreach my $token (@$tokens) {
        if ($token->[0] eq 'text') {
            
            if ($current_block_tag) { # In a block, push text and loop
                push @collected, $token;
                next;
            }
            
            # Not in a block
            if ($token->[1] eq "\n") { # New line, start caring (looking for blocks) again
                $care = 1;
                $lspace = 0;
            }
            elsif ($care && $token->[1] =~ /^([ ]+)$/) { # If we get too much whitespace, stop caring
                $care = 0 if ( ($lspace += length($1) ) > $less_than_tab);
            }
            else {
                $care = 0;
            }
            push @output, $token;
        }
        else { # Is a tag
            #warn("Got tag token: " . Dumper($token));
            
            if ($current_block_tag) { # If in tag already
                push @collected, $token; # Always collect this token, even if it's the end tag
            
                if ($token->[1] eq $current_block_end_tag) { # End tag for current block
                    $nesting_level--;
                    if (0 == $nesting_level) {# If end of current block.
                        my $block = join('', map { $_->[1] } @collected);
                        #warn("BLOCK {$block}");
                        my $key = _md5_utf8($block);
                        $self->{_html_blocks}{$key} = $block;
                        push(@output, ['text', "\n\n" . $key . "\n\n"]);
                        @collected = ();
                        $current_block_tag = $current_block_end_tag = undef;
                        $care = 0; # Do not care about anything left on the line
                    }
                }
                elsif ($token->[2] eq $current_block_tag) { # Another occurance of the same tag
                    $nesting_level++;
                }
            }
            else { # Not in tag already
                #warn("Not in tag already");
                #warn("Care $care, lspace $lspace block tag" . $block_tags{$token->[2]});
                
                # If we care about tags here, and we find a tag we care about
                if ($care && ($current_block_end_tag = $block_tags{$token->[2]}) ) {
                    #warn("IN TAG");
                    $nesting_level++;
                    $current_block_tag = $token->[2];
                    push @collected, $token;
                }
                else {
                    push @output, $token;
                }
            }
        }
    }

	$text = join '', map { $_->[1] } @output;

	# Special case just for <hr />. It was easier to make a special case than
	# to make the other regex more complicated.	
	$text = $self->_HashHR($text);
	
    $text = $self->_HashHTMLComments($text);

    $text = $self->_HashPHPASPBlocks($text);

    #warn ("OUT _HashHTMLBlocks for text {$text}");

	return $text;
}

sub _HashHR {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;
    
	$text =~ s{
				(?:
					(?<=\n\n)		# Starting after a blank line
					|				# or
					\A\n?			# the beginning of the doc
				)
				(						# save in $1
					[ ]{0,$less_than_tab}
					<(hr)				# start tag = $2
					\b					# word break
					([^<>])*?			# 
					/?>					# the matching end tag
					[ \t]*
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
				)
	}{
		my $key = _md5_utf8($1);
		$self->{_html_blocks}{$key} = $1;
		"\n\n" . $key . "\n\n";
	}egx;
			
	return $text;
}

sub _HashHTMLComments {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;
    
    # Special case for standalone HTML comments:
	$text =~ s{
				(?:
					(?<=\n\n)		# Starting after a blank line
					|				# or
					\A\n?			# the beginning of the doc
				)
				(						# save in $1
					[ ]{0,$less_than_tab}
					(?s:
						<!
						(--.*?--\s*)+
						>
					)
					[ \t]*
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
				)
	}{
		my $key = _md5_utf8($1);
		$self->{_html_blocks}{$key} = $1;
		"\n\n" . $key . "\n\n";
	}egx;
	
	return $text;
}

sub _HashPHPASPBlocks {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;
    
    # PHP and ASP-style processor instructions (<?…?> and <%…%>)
	$text =~ s{
				(?:
					(?<=\n\n)		# Starting after a blank line
					|				# or
					\A\n?			# the beginning of the doc
				)
				(						# save in $1
					[ ]{0,$less_than_tab}
					(?s:
						<([?%])			# $2
						.*?
						\2>
					)
					[ \t]*
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
				)
			}{
				my $key = _md5_utf8($1);
				$self->{_html_blocks}{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egx;
	return $text;
}

sub _RunBlockGamut {
#
# These are all the transformations that form block-level
# tags like paragraphs, headers, and list items.
#
    my ($self, $text) = @_;

    # Do headers first, as these populate cross-refs
    $text = $self->_DoHeaders($text);
    
    # Do tables first to populate the table id's for cross-refs
    # (but after headers as the tables can contain cross-refs to other things, so we want the header cross-refs)
    # Escape <pre><code> so we don't get greedy with tables
    $text = $self->_DoTables($text);
    
    # And now, protect our tables
    $text = $self->_HashHTMLBlocks($text) unless $self->{markdown_in_html_blocks};

    # Do Horizontal Rules:
    $text =~ s{^[ ]{0,2}([ ]?\*[ ]?){3,}[ \t]*$}{\n<hr$self->{empty_element_suffix}\n}gmx;
    $text =~ s{^[ ]{0,2}([ ]? -[ ]?){3,}[ \t]*$}{\n<hr$self->{empty_element_suffix}\n}gmx;
    $text =~ s{^[ ]{0,2}([ ]? _[ ]?){3,}[ \t]*$}{\n<hr$self->{empty_element_suffix}\n}gmx;

    $text = $self->_DoLists($text);

    $text = $self->_DoCodeBlocks($text);

    $text = $self->_DoBlockQuotes($text);

    # We already ran _HashHTMLBlocks() before, in Markdown(), but that
    # was to escape raw HTML in the original Markdown source. This time,
    # we're escaping the markup we've just created, so that we don't wrap
    # <p> tags around block-level tags.
    $text = $self->_HashHTMLBlocks($text);

    # Escape <pre><code> so we don't get greedy with tables
#   $text = _DoTables($text);
    
    # And now, protect our tables
#   $text = _HashHTMLBlocks($text);

    $text = $self->_FormParagraphs($text);

    return $text;
}

sub _RunSpanGamut {
#
# These are all the transformations that occur *within* block-level
# tags like paragraphs, headers, and list items.
#
    my ($self, $text) = @_;

    $text = $self->_DoCodeSpans($text);
	$text = $self->_EscapeSpecialCharsWithinTagAttributes($text);
    $text = $self->_EscapeSpecialChars($text);

    # Process anchor and image tags. Images must come first,
    # because ![foo][f] looks like an anchor.
    $text = $self->_DoImages($text);
    $text = $self->_DoAnchors($text);

    # Process WikiWords
    if ($self->_UseWikiLinks()) {
        $text = $self->_DoWikiLinks($text);
        
        # And then reprocess anchors and images
        $text = $self->_DoImages($text);
        $text = $self->_DoAnchors($text);
    }
    

    # Make links out of things like `<http://example.com/>`
    # Must come after _DoAnchors(), because you can use < and >
    # delimiters in inline links like [this](<url>).
    $text = $self->_DoAutoLinks($text);

    $text = $self->_EncodeAmpsAndAngles($text);

    $text = $self->_DoItalicsAndBold($text);

    # Do hard breaks:
    $text =~ s/ {2,}\n/ <br$self->{empty_element_suffix}\n/g;

    return $text;
}

sub _EscapeSpecialChars {
    my ($self, $text) = @_;
    my $tokens ||= $self->_TokenizeHTML($text);

    $text = '';   # rebuild $text from the tokens
#   my $in_pre = 0;  # Keep track of when we're inside <pre> or <code> tags.
#   my $tags_to_skip = qr!<(/?)(?:pre|code|kbd|script|math)[\s>]!;

    foreach my $cur_token (@$tokens) {
        if ($cur_token->[0] eq "tag") {
            # Within tags, encode * and _ so they don't conflict
            # with their use in Markdown for italics and strong.
            # We're replacing each such character with its
            # corresponding MD5 checksum value; this is likely
            # overkill, but it should prevent us from colliding
            # with the escape values by accident.
            $cur_token->[1] =~  s! \* !$g_escape_table{'*'}!ogx;
            $cur_token->[1] =~  s! _  !$g_escape_table{'_'}!ogx;
            $text .= $cur_token->[1];
        } 
        else {
            my $t = $cur_token->[1];
            $t = $self->_EncodeBackslashEscapes($t);
            $text .= $t;
        }
    }
    return $text;
}

sub _EscapeSpecialCharsWithinTagAttributes {
#
# Within tags -- meaning between < and > -- encode [\ ` * _] so they
# don't conflict with their use in Markdown for code, italics and strong.
# We're replacing each such character with its corresponding MD5 checksum
# value; this is likely overkill, but it should prevent us from colliding
# with the escape values by accident.
#
	my ($self, $text) = @_;
	my $tokens ||= $self->_TokenizeHTML($text);
	$text = '';   # rebuild $text from the tokens

	foreach my $cur_token (@$tokens) {
		if ($cur_token->[0] eq "tag") {
			$cur_token->[1] =~  s! \\ !$g_escape_table{'\\'}!gox;
			$cur_token->[1] =~  s{ (?<=.)</?code>(?=.)  }{$g_escape_table{'`'}}gox;
			$cur_token->[1] =~  s! \* !$g_escape_table{'*'}!gox;
			$cur_token->[1] =~  s! _  !$g_escape_table{'_'}!gox;
		}
		$text .= $cur_token->[1];
	}
	return $text;
}

sub _DoAnchors {
#
# Turn Markdown link shortcuts into XHTML <a> tags.
#
    my ($self, $text) = @_;

    #
    # First, handle reference-style links: [link text] [id]
    #
    $text =~ s{
        (                   # wrap whole match in $1
          \[
            ($g_nested_brackets)    # link text = $2
          \]

          [ ]?              # one optional space
          (?:\n[ ]*)?       # one optional newline followed by spaces

          \[
            (.*?)       # id = $3
          \]
        )
    }{
        my $result;
        my $whole_match = $1;
        my $link_text   = $2;
        my $link_id     = lc $3;

        if ($link_id eq "") {
            $link_id = lc $link_text;   # for shortcut links like [this][].
        }

        # Allow automatic cross-references to headers
        my $label = $self->_Header2Label($link_id);
        if (defined $self->{_crossrefs}{$label}) {
            my $url = $self->{_crossrefs}{$label};
            $url =~ s! \* !$g_escape_table{'*'}!gox;     # We've got to encode these to avoid
            $url =~ s!  _ !$g_escape_table{'_'}!gox;     # conflicting with italics/bold.
            $result = qq[<a href="$url"];
            if ( defined $self->{_titles}{$label} ) {
                my $title = $self->{_titles}{$label};
                $title =~ s! \* !$g_escape_table{'*'}!gox;
                $title =~ s!  _ !$g_escape_table{'_'}!gox;
                $result .=  " title=\"$title\"";
            }
            $result .= $self->_DoAttributes($label);
            $result .= ">$link_text</a>";
        } 
        elsif (defined $self->{_urls}{$link_id}) {
            my $url = $self->{_urls}{$link_id};
            $url =~ s! \* !$g_escape_table{'*'}!gox;     # We've got to encode these to avoid
            $url =~ s!  _ !$g_escape_table{'_'}!gox;     # conflicting with italics/bold.
            $result = "<a href=\"$url\"";
            if ( defined $self->{_titles}{$link_id} ) {
                my $title = $self->{_titles}{$link_id};
                $title =~ s! \* !$g_escape_table{'*'}!gox;
                $title =~ s!  _ !$g_escape_table{'_'}!gox;
                $result .=  qq{ title="$title"};
            }
            $result .= $self->_DoAttributes($label);
            $result .= ">$link_text</a>";
        }
        else {
            $result = $whole_match;
        }
        $result;
    }xsge;

    #
    # Next, inline-style links: [link text](url "optional title")
    #
    $text =~ s{
        (               # wrap whole match in $1
          \[
            ($g_nested_brackets)    # link text = $2
          \]
          \(            # literal paren
            [ \t]*
            ($g_nested_parens)   # href = $3
            [ \t]*
            (           # $4
              (['"])    # quote char = $5
              (.*?)     # Title = $6
              \5        # matching quote
              [ \t]*	# ignore any spaces/tabs between closing quote and )
            )?          # title is optional
          \)
        )
    }{
        my $result;
        my $whole_match = $1;
        my $link_text   = $2;
        my $url         = $3;
        my $title       = $6;
        
        $url =~ s! \* !$g_escape_table{'*'}!ogx;     # We've got to encode these to avoid
        $url =~ s!  _ !$g_escape_table{'_'}!ogx;     # conflicting with italics/bold.
        $url =~ s{^<(.*)>$}{$1};					# Remove <>'s surrounding URL, if present
        $result = "<a href=\"$url\"";

        if (defined $title) {
            $title =~ s/"/&quot;/g;
            $title =~ s! \* !$g_escape_table{'*'}!ogx;
            $title =~ s!  _ !$g_escape_table{'_'}!ogx;
            $result .=  " title=\"$title\"";
        }

        $result .= ">$link_text</a>";

        $result;
    }xsge;
    
    #
	# Last, handle reference-style shortcuts: [link text]
	# These must come last in case you've also got [link test][1]
	# or [link test](/foo)
	#
	$text =~ s{
		(					# wrap whole match in $1
		  \[
		    ([^\[\]]+)		# link text = $2; can't contain '[' or ']'
		  \]
		)
	}{
		my $result;
		my $whole_match = $1;
		my $link_text   = $2;
		(my $link_id = lc $2) =~ s{[ ]?\n}{ }g; # lower-case and turn embedded newlines into spaces

		if (defined $self->{_urls}{$link_id}) {
			my $url = $self->{_urls}{$link_id};
			$url =~ s! \* !$g_escape_table{'*'}!ogx;		# We've got to encode these to avoid
			$url =~ s!  _ !$g_escape_table{'_'}!ogx;		# conflicting with italics/bold.
			$result = "<a href=\"$url\"";
			if ( defined $self->{titles}{$link_id} ) {
				my $title = $self->{titles}{$link_id};
				$title =~ s! \* !$g_escape_table{'*'}!ogx;
				$title =~ s!  _ !$g_escape_table{'_'}!ogx;
				$result .=  qq{ title="$title"};
			}
			$result .= ">$link_text</a>";
		}
		else {
			$result = $whole_match;
		}
		$result;
	}xsge;

    return $text;
}

sub _DoImages {
#
# Turn Markdown image shortcuts into <img> tags.
#
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
        my $result;
        my $whole_match = $1;
        my $alt_text    = $2;
        my $link_id     = lc $3;

        if ($link_id eq "") {
            $link_id = lc $alt_text;     # for shortcut links like ![this][].
        }

        $alt_text =~ s/"/&quot;/g;
        if (defined $self->{_urls}{$link_id}) {
            my $url = $self->{_urls}{$link_id};
            $url =~ s! \* !$g_escape_table{'*'}!ogx;     # We've got to encode these to avoid
            $url =~ s!  _ !$g_escape_table{'_'}!ogx;     # conflicting with italics/bold.
            
            my $label = $self->_Header2Label($alt_text);
            $self->{_crossrefs}{$label} = "#$label";
            #if (! defined $self->{_titles}{$link_id}) {
            #    $self->{_titles}{$link_id} = $alt_text;
            #}
            
            $label = $self->{img_ids} ? qq{ id="$label"} : '';
            $result = qq{<img$label src="$url" alt="$alt_text"};
            if (length $link_id && defined $self->{_titles}{$link_id} && length $self->{_titles}{$link_id}) {
                my $title = $self->{_titles}{$link_id};
                $title =~ s! \* !$g_escape_table{'*'}!ogx;
                $title =~ s!  _ !$g_escape_table{'_'}!ogx;
                $result .=  qq{ title="$title"};
            }
            $result .= $self->_DoAttributes($link_id);
            $result .= $self->{empty_element_suffix};
            
        }
        else {
            # If there's no such link ID, leave intact:
            $result = $whole_match;
        }

        $result;
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
            ($g_nested_parens)  # src url - href = $3
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
        my $url         = $3;
        my $title       = '';
        if (defined($6)) {
            $title      = $6;
        }

        $alt_text =~ s/"/&quot;/g;
        $title    =~ s/"/&quot;/g;
        $url =~ s! \* !$g_escape_table{'*'}!ogx;     # We've got to encode these to avoid
        $url =~ s!  _ !$g_escape_table{'_'}!ogx;     # conflicting with italics/bold.
        $url =~ s{^<(.*)>$}{$1};					# Remove <>'s surrounding URL, if present

        my $label = $self->_Header2Label($alt_text);
        $self->{_crossrefs}{$label} = "#$label";
#       $self->{_titles}{$label} = $alt_text;          # FIXME - I think this line should not be here

        $label = $self->{img_ids} ? qq{ id="$label"} : '';
        $result = qq{<img$label src="$url" alt="$alt_text"};
        if (defined $title && length $title) {
            $title =~ s! \* !$g_escape_table{'*'}!ogx;
            $title =~ s!  _ !$g_escape_table{'_'}!ogx;
            $result .=  qq{ title="$title"};
        }
        $result .= $self->{empty_element_suffix};
        
        $result;
    }xsge;

    return $text;
}

sub _DoHeaders {
    my ($self, $text) = @_;
    my $header = "";
    my $label = "";
    
    # Don't do Wiki Links in Headers
    local $self->{use_wikilinks} = 0;
    
    # Setext-style headers:
    #     Header 1
    #     ========
    #  
    #     Header 2
    #     --------
    #
    $text =~ s{ ^(.+)[ \t]*\n=+[ \t]*\n+ }{
        $label = $self->{heading_ids} ? q{ id="} . $self->_Header2Label($1) . q{"} : '';
        $header = $self->_RunSpanGamut($1);
        
        if ($label ne '') {
            $self->{_crossrefs}{$label} = "#$label";
            $self->{_titles}{$label} = $header;
        }
        
        "<h1$label>"  .  $self->_RunSpanGamut($1)  .  "</h1>\n\n";
    }egmx;

    $text =~ s{ ^(.+)[ \t]*\n-+[ \t]*\n+ }{
        $label = $self->{heading_ids} ? q{ id="} . $self->_Header2Label($1) . q{"} : '';
        $header = $self->_RunSpanGamut($1);
        
        if ($label ne '') {
            $self->{_crossrefs}{$label} = "#$label";
            $self->{_titles}{$label} = $header;
        }
        
        "<h2$label>"  .  $self->_RunSpanGamut($1)  .  "</h2>\n\n";
    }egmx;


    # atx-style headers:
    #   # Header 1
    #   ## Header 2
    #   ## Header 2 with closing hashes ##
    #   ...
    #   ###### Header 6
    #
    my $l;
    $text =~ s{
            ^(\#{1,6})  # $1 = string of #'s
            [ \t]*
            (.+?)       # $2 = Header text
            [ \t]*
            \#*         # optional closing #'s (not counted)
            \n+
        }{
            my $h_level = length($1);
            $header = $self->_RunSpanGamut($2);
            
            if ($self->{heading_ids}) {
                $label = $self->_Header2Label($2);
                $self->{_crossrefs}{$label} = "#$label";
                $self->{_titles}{$label} = $header;
            }
            $l = $self->{heading_ids} ? $h_level . ' id="' . $label . '"' : $h_level;
            "<h$l>"  .  $header  .  "</h$h_level>\n\n";
        }egmx;

    return $text;
}

sub _DoLists {
#
# Form HTML ordered (numbered) and unordered (bulleted) lists.
#
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;

    # Re-usable patterns to match list item bullets and number markers:
    my $marker_ul  = qr/[*+-]/;
    my $marker_ol  = qr/\d+[.]/;
    my $marker_any = qr/(?:$marker_ul|$marker_ol)/;

    # Re-usable pattern to match any entirel ul or ol list:
    my $whole_list = qr{
        (                               # $1 = whole list
          (                             # $2
            [ ]{0,$less_than_tab}
            (${marker_any})             # $3 = first list item marker
            [ \t]+
          )
          (?s:.+?)
          (                             # $4
              \z
            |
              \n{2,}
              (?=\S)
              (?!                       # Negative lookahead for another list item marker
                [ \t]*
                ${marker_any}[ \t]+
              )
          )
        )
    }mx;

    # We use a different prefix before nested lists than top-level lists.
    # See extended comment in _ProcessListItems().
    #
    # Note: There's a bit of duplication here. My original implementation
    # created a scalar regex pattern as the conditional result of the test on
    # $self->{_list_level}, and then only ran the $text =~ s{...}{...}egmx
    # substitution once, using the scalar as the pattern. This worked,
    # everywhere except when running under MT on my hosting account at Pair
    # Networks. There, this caused all rebuilds to be killed by the reaper (or
    # perhaps they crashed, but that seems incredibly unlikely given that the
    # same script on the same server ran fine *except* under MT. I've spent
    # more time trying to figure out why this is happening than I'd like to
    # admit. My only guess, backed up by the fact that this workaround works,
    # is that Perl optimizes the substition when it can figure out that the
    # pattern will never change, and when this optimization isn't on, we run
    # afoul of the reaper. Thus, the slightly redundant code to that uses two
    # static s/// patterns rather than one conditional pattern.

    if ($self->{_list_level}) {
        $text =~ s{
                ^
                $whole_list
            }{
                my $list = $1;
                my $list_type = ($3 =~ m/$marker_ul/) ? "ul" : "ol";
                # Turn double returns into triple returns, so that we can make a
                # paragraph for the last item in a list, if necessary:
                $list =~ s/\n{2,}/\n\n\n/g;
                my $result = ( $list_type eq 'ul' ) ?
                    $self->_ProcessListItems($list, $marker_ul)
                  : $self->_ProcessListItems($list, $marker_ol);
                $result = "<$list_type>\n" . $result . "</$list_type>\n";
                $result;
            }egmx;
    }
    else {
        $text =~ s{
                (?:(?<=\n\n)|\A\n?)
                $whole_list
            }{
                my $list = $1;
                my $list_type = ($3 =~ m/$marker_ul/) ? "ul" : "ol";
                # Turn double returns into triple returns, so that we can make a
                # paragraph for the last item in a list, if necessary:
                $list =~ s/\n{2,}/\n\n\n/g;
                my $result = ( $list_type eq 'ul' ) ?
                    $self->_ProcessListItems($list, $marker_ul)
                  : $self->_ProcessListItems($list, $marker_ol);
                $result = "<$list_type>\n" . $result . "</$list_type>\n";
                $result;
            }egmx;
    }


    return $text;
}

sub _ProcessListItems {
#
#   Process the contents of a single ordered or unordered list, splitting it
#   into individual list items.
#

    my ($self, $list_str, $marker_any) = @_;


    # The $self->{_list_level} global keeps track of when we're inside a list.
    # Each time we enter a list, we increment it; when we leave a list,
    # we decrement. If it's zero, we're not in a list anymore.
    #
    # We do this because when we're not inside a list, we want to treat
    # something like this:
    #
    #       I recommend upgrading to version
    #       8. Oops, now this line is treated
    #       as a sub-list.
    #
    # As a single paragraph, despite the fact that the second line starts
    # with a digit-period-space sequence.
    #
    # Whereas when we're inside a list (or sub-list), that line will be
    # treated as the start of a sub-list. What a kludge, huh? This is
    # an aspect of Markdown's syntax that's hard to parse perfectly
    # without resorting to mind-reading. Perhaps the solution is to
    # change the syntax rules such that sub-lists must start with a
    # starting cardinal number; e.g. "1." or "a.".

    $self->{_list_level}++;

    # trim trailing blank lines:
    $list_str =~ s/\n{2,}\z/\n/;


    $list_str =~ s{
        (\n)?                           # leading line = $1
        (^[ \t]*)                       # leading whitespace = $2
        ($marker_any) [ \t]+            # list marker = $3
        ((?s:.+?)                       # list item text   = $4
        (\n{1,2}))
        (?= \n* (\z | \2 ($marker_any) [ \t]+))
    }{
        my $item = $4;
        my $leading_line = $1;
        my $leading_space = $2;

        if ($leading_line or ($item =~ m/\n{2,}/)) {
            $item = $self->_RunBlockGamut($self->_Outdent($item));
        }
        else {
            # Recursion for sub-lists:
            $item = $self->_DoLists($self->_Outdent($item));
            chomp $item;
            $item = $self->_RunSpanGamut($item);
        }

        "<li>" . $item . "</li>\n";
    }egmx;

    $self->{_list_level}--;
    return $list_str;
}

sub _DoCodeBlocks {
#
#   Process Markdown `<pre><code>` blocks.
#   

    my ($self, $text) = @_;

 	$text =~ s{
		(?:\n\n|\A)
		(	            # $1 = the code block -- one or more lines, starting with a space/tab
		  (?:
		    (?:[ ]{$self->{tab_width}} | \t)  # Lines must start with a tab or a tab-width of spaces
		    .*\n+
		  )+
		)
		((?=^[ ]{0,$self->{tab_width}}\S)|\Z)	# Lookahead for non-space at line-start, or end of doc
	}{
    	my $codeblock = $1;
    	my $result; # return value

    	$codeblock = $self->_EncodeCode($self->_Outdent($codeblock));
    	$codeblock = $self->_Detab($codeblock);
    	$codeblock =~ s/\A\n+//; # trim leading newlines
    	$codeblock =~ s/\n+\z//; # trim trailing newlines

    	$result = "\n\n<pre><code>" . $codeblock . "\n</code></pre>\n\n";

    	$result;
	}egmx;

	return $text;
}

sub _DoCodeSpans {
#
#   *   Backtick quotes are used for <code></code> spans.
# 
#   *   You can use multiple backticks as the delimiters if you want to
#       include literal backticks in the code span. So, this input:
#     
#         Just type ``foo `bar` baz`` at the prompt.
#     
#       Will translate to:
#     
#         <p>Just type <code>foo `bar` baz</code> at the prompt.</p>
#     
#       There's no arbitrary limit to the number of backticks you
#       can use as delimters. If you need three consecutive backticks
#       in your code, use four for delimiters, etc.
#
#   *   You can use spaces to get literal backticks at the edges:
#     
#         ... type `` `bar` `` ...
#     
#       Turns to:
#     
#         ... type <code>`bar`</code> ...
#

    my ($self, $text) = @_;

	$text =~ s@
			(?<!\\)		# Character before opening ` can't be a backslash
			(`+)		# $1 = Opening run of `
			(.+?)		# $2 = The code block
			(?<!`)
			\1			# Matching closer
			(?!`)
		@
 			my $c = "$2";
 			$c =~ s/^[ \t]*//g; # leading whitespace
 			$c =~ s/[ \t]*$//g; # trailing whitespace
 			$c = $self->_EncodeCode($c);
			"<code>$c</code>";
		@egsx;

    return $text;
}

sub _EncodeCode {
#
# Encode/escape certain characters inside Markdown code runs.
# The point is that in code, these characters are literals,
# and lose their special Markdown meanings.
#
    my $self = shift;
    local $_ = shift;

    # Protect Wiki Links in Code Blocks
    if ($self->_UseWikiLinks()) {
        my $WikiWord = '[A-Z]+[a-z\x80-\xff]+[A-Z][A-Za-z\x80-\xff]*';
        s/($WikiWord)/\\$1/gx;
    }
    
    # Encode all ampersands; HTML entities are not
    # entities within a Markdown code span.
    s/&/&amp;/g;

    # Encode $'s, but only if we're running under Blosxom.
    # (Blosxom interpolates Perl variables in article bodies.)
    {
        no warnings 'once';
        if (defined($blosxom::version)) {
            s/\$/&#036;/g;  
        }
    }


    # Do the angle bracket song and dance:
    s! <  !&lt;!gx;
    s! >  !&gt;!gx;

    # Now, escape characters that are magic in Markdown:
    s! \* !$g_escape_table{'*'}!ogx;
    s! _  !$g_escape_table{'_'}!ogx;
    s! {  !$g_escape_table{'{'}!ogx;
    s! }  !$g_escape_table{'}'}!ogx;
    s! \[ !$g_escape_table{'['}!ogx;
    s! \] !$g_escape_table{']'}!ogx;
    s! \\ !$g_escape_table{'\\'}!ogx;

    return $_;
}

sub _DoItalicsAndBold {
    my ($self, $text) = @_;

    # Handle at beginning of lines:
    $text =~ s{ ^(\*\*|__) (?=\S) (.+?[*_]*) (?<=\S) \1 }
        {<strong>$2</strong>}gsx;

    $text =~ s{ ^(\*|_) (?=\S) (.+?) (?<=\S) \1 }
        {<em>$2</em>}gsx;

    # <strong> must go first:
    $text =~ s{ (?<=\W) (\*\*|__) (?=\S) (.+?[*_]*) (?<=\S) \1 }
        {<strong>$2</strong>}gsx;

    $text =~ s{ (?<=\W) (\*|_) (?=\S) (.+?) (?<=\S) \1 }
        {<em>$2</em>}gsx;

    # And now, a second pass to catch nested strong and emphasis special cases
    $text =~ s{ (?<=\W) (\*\*|__) (?=\S) (.+?[*_]*) (?<=\S) \1 }
        {<strong>$2</strong>}gsx;

    $text =~ s{ (?<=\W) (\*|_) (?=\S) (.+?) (?<=\S) \1 }
        {<em>$2</em>}gsx;

    return $text;
}

sub _DoBlockQuotes {
    my ($self, $text) = @_;

    $text =~ s{
          (                             # Wrap whole match in $1
            (
              ^[ \t]*>[ \t]?            # '>' at the start of a line
                .+\n                    # rest of the first line
              (.+\n)*                   # subsequent consecutive lines
              \n*                       # blanks
            )+
          )
        }{
            my $bq = $1;
            $bq =~ s/^[ \t]*>[ \t]?//gm;    # trim one level of quoting
            $bq =~ s/^[ \t]+$//mg;          # trim whitespace-only lines
            $bq = $self->_RunBlockGamut($bq);      # recurse

            $bq =~ s/^/  /mg;
            # These leading spaces screw with <pre> content, so we need to fix that:
            $bq =~ s{
                    (\s*<pre>.+?</pre>)
                }{
                    my $pre = $1;
                    $pre =~ s/^  //mg;
                    $pre;
                }egsx;

            "<blockquote>\n$bq\n</blockquote>\n\n";
        }egmx;


    return $text;
}

sub _FormParagraphs {
#
#   Params:
#       $text - string to process with html <p> tags
#
    my ($self, $text) = @_;

    # Strip leading and trailing lines:
    $text =~ s/\A\n+//;
    $text =~ s/\n+\z//;

    my @grafs = split(/\n{2,}/, $text);

    #
    # Wrap <p> tags.
    #
    foreach (@grafs) {
        unless (defined( $self->{_html_blocks}{$_} )) {
            $_ = $self->_RunSpanGamut($_);
            s/^([ \t]*)/<p>/;
            $_ .= "</p>";
        }
    }

    #
    # Unhashify HTML blocks
    #
    foreach (@grafs) {
        if (defined( $self->{_html_blocks}{$_} )) {
            $_ = $self->{_html_blocks}{$_};
        }
    }

    return join "\n\n", @grafs;
}

sub _EncodeAmpsAndAngles {
# Smart processing for ampersands and angle brackets that need to be encoded.

    my ($self, $text) = @_;
    return '' if (!defined $text or !length $text);

    # Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
    #   http://bumppo.net/projects/amputator/
    $text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/&amp;/g;

    # Encode naked <'s
    $text =~ s{<(?![a-z/?\$!])}{&lt;}gi;
    
    # And >'s - added by Fletcher Penney
#   $text =~ s{>(?![a-z/?\$!])}{&gt;}gi;
#   Causes problems...

    # Remove encoding inside comments
    $text =~ s{
        (?<=<!--) # Begin comment
        (.*?)     # Anything inside
        (?=-->)   # End comments
    }{
        my $t = $1;
        $t =~ s/&amp;/&/g;
        $t =~ s/&lt;/</g;
        $t;
    }egsx;

    return $text;
}

sub _EncodeBackslashEscapes {
#
#   Parameter:  String.
#   Returns:    The string, with after processing the following backslash
#               escape sequences.
#
    my $self = shift;
    local $_ = shift;

    s! \\\\  !$g_escape_table{'\\'}!ogx;     # Must process escaped backslashes first.
    s! \\`   !$g_escape_table{'`'}!ogx;
    s! \\\*  !$g_escape_table{'*'}!ogx;
    s! \\_   !$g_escape_table{'_'}!ogx;
    s! \\\{  !$g_escape_table{'{'}!ogx;
    s! \\\}  !$g_escape_table{'}'}!ogx;
    s! \\\[  !$g_escape_table{'['}!ogx;
    s! \\\]  !$g_escape_table{']'}!ogx;
    s! \\\(  !$g_escape_table{'('}!ogx;
    s! \\\)  !$g_escape_table{')'}!ogx;
    s! \\>   !$g_escape_table{'>'}!ogx;
    s! \\\#  !$g_escape_table{'#'}!ogx;
    s! \\\+  !$g_escape_table{'+'}!ogx;
    s! \\\-  !$g_escape_table{'-'}!ogx;
    s! \\\.  !$g_escape_table{'.'}!ogx;
    s{ \\!  }{$g_escape_table{'!'}}ogx;

    return $_;
}


sub _DoAutoLinks {
    my ($self, $text) = @_;

    $text =~ s{<((https?|ftp):[^'">\s]+)>}{<a href="$1">$1</a>}gi;

    # Email addresses: <address@domain.foo>
    $text =~ s{
        <
        (?:mailto:)?
        (
            [-.\w]+
            \@
            [-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+
        )
        >
    }{
        $self->_EncodeEmailAddress( $self->_UnescapeSpecialChars($1) );
    }egix;

    return $text;
}


sub _EncodeEmailAddress {
#
#   Input: an email address, e.g. "foo@example.com"
#
#   Output: the email address as a mailto link, with each character
#       of the address encoded as either a decimal or hex entity, in
#       the hopes of foiling most address harvesting spam bots. E.g.:
#
#     <a href="&#x6D;&#97;&#105;&#108;&#x74;&#111;:&#102;&#111;&#111;&#64;&#101;
#       x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;">&#102;&#111;&#111;
#       &#64;&#101;x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;</a>
#
#   Based on a filter by Matthew Wickline, posted to the BBEdit-Talk
#   mailing list: <http://tinyurl.com/yu7ue>
#

    my ($self, $addr) = @_;

    my @encode = (
        sub { '&#' .                 ord(shift)   . ';' },
        sub { '&#x' . sprintf( "%X", ord(shift) ) . ';' },
        sub {                            shift          },
    );

    $addr = "mailto:" . $addr;

    $addr =~ s{(.)}{
        my $char = $1;
        if ( $char eq '@' ) {
            # this *must* be encoded. I insist.
            $char = $encode[int rand 1]->($char);
        } 
        elsif ( $char ne ':' ) {
            # leave ':' alone (to spot mailto: later)
            my $r = rand;
            # roughly 10% raw, 45% hex, 45% dec
            $char = (
                $r > .9   ?  $encode[2]->($char)  :
                $r < .45  ?  $encode[1]->($char)  :
                             $encode[0]->($char)
            );
        }
        $char;
    }gex;

    $addr = qq{<a href="$addr">$addr</a>};
    $addr =~ s{">.+?:}{">}; # strip the mailto: from the visible part

    return $addr;
}


sub _UnescapeSpecialChars {
#
# Swap back in all the special characters we've hidden.
#
    my ($self, $text) = @_;

    while( my($char, $hash) = each(%g_escape_table) ) {
        $text =~ s/$hash/$char/g;
    }
    return $text;
}


sub _TokenizeHTML {
#
#   Parameter:  String containing HTML markup.
#   Returns:    Reference to an array of the tokens comprising the input
#               string. Each token is either a tag (possibly with nested,
#               tags contained therein, such as <a href="<MTFoo>">, or a
#               run of text between tags. Each element of the array is a
#               two-element array; the first is either 'tag' or 'text';
#               the second is the actual value.
#
#
#   Derived from the _tokenize() subroutine from Brad Choate's MTRegex plugin.
#       <http://www.bradchoate.com/past/mtregex.php>
#
    my ($self, $str) = @_;
    my $pos = 0;
    my $len = length $str;
    my @tokens;

    my $depth = 6;
    my $nested_tags = join('|', ('(?:<[a-z/!$](?:[^<>]') x $depth) . (')*>)' x  $depth);
    my $match = qr/(?s: <! ( -- .*? -- \s* )+ > ) |  # comment
                   (?s: <\? .*? \?> ) |              # processing instruction
                   $nested_tags/iox;                   # nested tags

    while ($str =~ m/($match)/og) {
        my $whole_tag = $1;
        my $sec_start = pos $str;
        my $tag_start = $sec_start - length $whole_tag;
        if ($pos < $tag_start) {
            push @tokens, $self->_TokenizeText( substr($str, $pos, $tag_start - $pos) );
        }
        $whole_tag =~ /^<\/?([^> \/]+)/;
        push @tokens, ['tag', $whole_tag, lc($1)];
        $pos = pos $str;
    }
    push @tokens, $self->_TokenizeText( substr($str, $pos, $len - $pos) ) if $pos < $len;
    return \@tokens;
}

sub _TokenizeText {
    my ($self, $text) = @_;
    
    # FIXME - Can this just become a split, or am I being over complex for a reason?
    my @tokens;
    
    while (my $l = length $text) {
        #warn("Tokenize $text");
        my $i; # Chop tokens so that new lines always get their own token, makes subsequent parsing easier.
        if (($i = index($text, "\n")) != -1) {
            #warn("MEEP for {$text}");
            push @tokens, ['text', substr($text, 0, $i)], ['text', "\n"];
            $text = substr($text, $i+1, $l-($i+1));
            #warn("REMAINING {$text}");
            #use Data::Dumper;
            #warn(Dumper(\@tokens));
        }
        else {
            push @tokens => ['text', $text];
            $text = '';
        }
        #warn("ABOUT TO LOOP {$text}");
    }
    return grep { length $_->[1] } @tokens;
}

sub _Outdent {
#
# Remove one level of line-leading tabs or spaces
#
    my ($self, $text) = @_;

    $text =~ s/^(\t|[ ]{1,$self->{tab_width}})//gm;
    return $text;
}


sub _Detab {
#
# Cribbed from a post by Bart Lateur:
# <http://www.nntp.perl.org/group/perl.macperl.anyperl/154>
#
    my ($self, $text) = @_;

    # FIXME - Better anchor/regex would be quicker.
    
    # Original:
    #$text =~ s{(.*?)\t}{$1.(' ' x ($self->{tab_width} - length($1) % $self->{tab_width}))}ge;
    
    # Much swifter, but pretty hateful:
    do {} while ($text =~ s{^(.*?)\t}{$1.(' ' x ($self->{tab_width} - length($1) % $self->{tab_width}))}mge);
    return $text;
}

#
# MultiMarkdown Routines
#

sub _ParseMetaData { # FIXME - This is really really ugly!
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
                if (!$g_metadata_newline{$currentKey}) {
                    $g_metadata_newline{$currentKey} = $g_metadata_newline{default};
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
                    $self->{_metadata}{$currentKey} .= "$g_metadata_newline{$currentKey}$1";
                }
            }
        } 
        else {
            $clean_text .= "$line\n";
        }
    }
        
    return $clean_text;
}

sub _StripFootnoteDefinitions {
    my ($self, $text) = @_;
    my $less_than_tab = $self->{tab_width} - 1;

    while ($text =~ s{
        \n\[\^(.+?)\]:[ \t]*# id = $1
        \n?
        (.*?)\n{1,2}        # end at new paragraph
        ((?=\n[ ]{0,$less_than_tab}\S)|\Z)  # Lookahead for non-space at line-start, or end of doc
    }
    {\n}sx)
    {
        my $id = $1;
        my $footnote = "$2\n";
        $footnote =~ s/^[ ]{0,$self->{tab_width}}//gm;
    
        $self->{_footnotes}{$self->_Header2Label($id)} = $footnote;
    }
    
    return $text;
}

sub _DoFootnotes {
    my ($self, $text) = @_;
    
    return '' unless length $text;
    
    # First, run routines that get skipped in footnotes
    foreach my $label (sort keys %{ $self->{_footnotes} }) {
        my $footnote = $self->_RunBlockGamut($self->{_footnotes}{$label});

        # strip leading and trailing <p> tags (they will be added later)
        $footnote =~ s/^<p>//s;
        $footnote =~ s/<\/p>$//s;
        $footnote = $self->_DoMarkdownCitations($footnote);
        $self->{_footnotes}{$label} = $footnote;
    }
    
    my $footnote_counter = 0;
        
    $text =~ s{
        \[\^(.*?)\]     # id = $1
    }{
        my $result;
        my $id = $self->_Header2Label($1);
        
        if (defined $self->{_footnotes}{$id} ) {
            $footnote_counter++;
            $result = qq{<a href="#$id" id="f$id" class="footnote">$footnote_counter</a>};
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
        #$result .= qq[<div id="$id"><p><a href="#f$id" class="reversefootnote">$footnote_counter.</a> $self->{_footnotes}{$id}</div>\n\n];
        $result .= qq[<li id="$id"><p>$self->{_footnotes}{$id}<a href="#f$id" class="reversefootnote">&#160;&#8617;</a></p></li>\n\n];
    }

    if ($footnote_counter > 0) {
        $result = qq[\n\n<div class="footnotes">\n<hr$self->{empty_element_suffix}\n<ol>\n\n] . $result . "</ol>\n</div>";
    } else {
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

sub _ConvertCopyright{
    my ($self, $text) = @_;
    # Convert to an XML compatible form of copyright symbol
    
    $text =~ s/&copy;/&#xA9;/gi;
    
    return $text;
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
            $result .= " $1=\"$2\"";
        }
        while ($self->{_attributes}{$id} =~ /(\S+)=(\S+)/g) {
            $result .= " $1=\"$2\"";
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
        my $result;
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
        else {
            # If there's no such link ID, leave intact:
            $result = $whole_match;
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


1;
__END__

=head1 OTHER IMPLEMENTATIONS

Markdown has been re-implemented in a number of languages, and with a number of additions.

Those that I have found are listed below:

=over

=item python - <http://www.freewisdom.org/projects/python-markdown/>

Python Markdown which is mostly compatible with the original, with an interesting extension API.

=item ruby (maruku) - <http://maruku.rubyforge.org/>

One of the nicest implementations out there. Builds a parse tree internally so very flexible.

=item php - <http://michelf.com/projects/php-markdown/>

A direct port of Markdown.pl, also has an 'extra' version, which adds a number of features that
were borrowed by MultiMarkdown

=item lua - <http://www.frykholm.se/files/markdown.lua>

Port to lua. Simple and lightweight (as lua is).

=item haskell - <http://johnmacfarlane.net/pandoc/>

Pandoc is a more general library, supporting Markdown, reStructuredText, LaTeX and more.

=item javascript - <http://www.attacklab.net/showdown-gui.html>

Direct(ish) port of Markdown.pl to JavaScript

=back

=head1 BUGS

To file bug reports or feature requests (other than topics listed in the
Caveats section above) please send email to:

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

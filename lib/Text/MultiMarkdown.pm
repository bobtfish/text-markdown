package Text::MultiMarkdown;
require 5.006_000;
use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use Encode      qw();

# Table of hash values for escaped characters:
my %g_escape_table;
foreach my $char (split //, '\\`*_{}[]()>#+-.!') {
    $g_escape_table{$char} = md5_hex($char);
}

=head1 METHODS

=head2 new

A simple constructor, see the SYNTAX and OPTIONS sections for more information.

=cut

sub markdown {
    my ( $text) = @_;

    # Clear the global hashes. If we don't clear these, you get conflicts
    # from other articles when generating a page which contains more than
    # one article (e.g. an index page that shows the N most recent
    # articles):
    
    $text = _RunBlockGamut($text);
    


        return $text . "\n";
    
}
my %html_blocks;

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

sub _HashHTMLBlocks {
    my ($text) = @_;
    my $less_than_tab = 3;

	# Hashify HTML blocks:
	# We only want to do this for block-level HTML tags, such as headers,
	# lists, and tables. That's because we still want to wrap <p>s around
	# "paragraphs" that are wrapped in non-block-level tags, such as anchors,
	# phrase emphasis, and spans. The list of tags we're looking for is
	# hard-coded:
	my $block_tags = qr{
		  (?:
			p         |  div     |  h[1-6]  |  blockquote  |  pre       |  table  |
			dl        |  ol      |  ul      |  script      |  noscript  |  form   |
			fieldset  |  iframe  |  math    |  ins         |  del
		  )
		}x;

	my $tag_attrs = qr{
						(?:				# Match one attr name/value pair
							\s+				# There needs to be at least some whitespace
											# before each attribute name.
							[\w.:_-]+		# Attribute name
							\s*=\s*
							(?:
								".+?"		# "Attribute value"
							 |
								'.+?'		# 'Attribute value'
							)
						)*				# Zero or more
					}x;

	my $empty_tag = qr{< \w+ $tag_attrs \s* />}xms;
	my $open_tag =  qr{< $block_tags $tag_attrs \s* >}xms;
	my $close_tag = undef;	# let Text::Balanced handle this

	use Text::Balanced qw(gen_extract_tagged);
	my $extract_block = gen_extract_tagged($open_tag, $close_tag, undef, { ignore => [$empty_tag] });

	my @chunks;
	## TO-DO: the 0,3 on the next line ought to respect the
	## tabwidth, or else, we should mandate 4-space tabwidth and
	## be done with it:
	while ($text =~ s{^(([ ]{0,3}<)?.*\n)}{}m) {
		my $cur_line = $1;
		if (defined $2) {
			# current line could be start of code block

			my ($tag, $remainder) = $extract_block->($cur_line . $text);
			if ($tag) {
				my $key = _md5_utf8($tag);
				$html_blocks{$key} = $tag;
				push @chunks, "\n\n" . $key . "\n\n";
				$text = $remainder;
			}
			else {
				# No tag match, so toss $cur_line into @chunks
				push @chunks, $cur_line;
			}
		}
		else {
			# current line could NOT be start of code block
			push @chunks, $cur_line;
		}

	}
	push @chunks, $text; # Whatever is left.

	$text = join '', @chunks;



	# Special case just for <hr />. It was easier to make a special case than
	# to make the other regex more complicated.	
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
				$html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egx;

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
				$html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egx;

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
				$html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egx;

	return $text;
}


sub _RunBlockGamut {
#
# These are all the transformations that form block-level
# tags like paragraphs, headers, and list items.
#
    my ($text) = @_;



    $text = _DoBlockQuotes($text);

    # we're escaping the markup we've just created, so that we don't wrap
    # <p> tags around block-level tags.
    $text = _HashHTMLBlocks($text);

 
    $text = _FormParagraphs($text);

    return $text;
}


sub _DoBlockQuotes {
    my ($text) = @_;

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
            
            $bq = _RunBlockGamut($bq);      # recurse

            $bq =~ s/^/  /g;
            
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
    my ($text) = @_;

    # Strip leading and trailing lines:
    $text =~ s/\A\n+//;
    $text =~ s/\n+\z//;

    my @grafs = split(/\n{2,}/, $text);

    #
    # Wrap <p> tags.
    #
    foreach (@grafs) {
        unless (defined( $html_blocks{$_} )) {
            s/^([ \t]*)/<p>/;
            $_ .= "</p>";
        }
    }

    #
    # Unhashify HTML blocks
    #
    foreach (@grafs) {
        if (defined( $html_blocks{$_} )) {
            $_ = $html_blocks{$_};
        }
    }

    return join "\n\n", @grafs;
}

1;

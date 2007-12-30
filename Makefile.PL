# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Text-MultiMarkdown';
author          'Darren M. Kulp <kulp@cpan.org>';
license			'bsd';
all_from        'lib/Text/MultiMarkdown.pm';

# Specific dependencies
requires        'MIME::Base64'    => undef;
requires        'List::Util'      => undef;
requires        'Digest::MD5'     => undef;
requires        'Scalar::Util'    => undef;
build_requires  'Test::More'      => '0.42';
build_requires  'Text::Exception' => undef;

auto_install;
WriteAll;


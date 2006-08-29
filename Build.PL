use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Text::MultiMarkdown',
    create_readme      => 1,
    test_files         => [ glob('t/*.t') ],
    dist_abstract      => 'Converts files in MultiMarkdown syntax to (X)HTML files',
);
$build->create_build_script;

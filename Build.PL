use 5.012;
use warnings;

use Module::Build;
use lib 'lib';
use Unicorn::Manager::Version;

my @script_files = grep { -f and ! -d } glob 'script/*';
my $v = Unicorn::Manager::Version->new;

my $build = Module::Build->new(
    module_name => 'Unicorn::Manager',
    dist_abstract => 'A Perl interface to the Unicorn webserver',
    dist_author   => 'Mugen Kenichi <mugen.kenichi@uninets.eu>',
    dist_version_from => 'lib/Unicorn/Manager/Version.pm',
    license => 'mit',

    configure_requires => {
        'Module::Build' => 0.38,
    },

    requires => {
        'Test::More'         => 0,
        'MooseX::Declare'    => 0.34,
        'File::Basename'     => 0,
        'Moose::Util::TypeConstraints' => 0,
        'YAML'               => 0,
        'JSON'               => 0,
        'Carp'               => 0,
        'Getopt::Long'       => 0,
    },

    build_requires => {
        'Module::Build' => 0.38,
    },

    script_files => [@script_files],

    add_to_cleanup => ['Unicorn-Manager-* Build _build MYMETA.*'],

    meta_add => {
        no_index => {
            directory => ['t'],
        },
        version => $v->get,
        release_status => 'unstable',
    },

    meta_merge => {
        provides => {
            'Unicorn::Manager' => {
                file => 'lib/Unicorn/Manager.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Proc' => {
                file => 'lib/Unicorn/Manager/Proc.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Types' => {
                file => 'lib/Unicorn/Manager/Types.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Version' => {
                file => 'lib/Unicorn/Manager/Version.pm',
                version => $v->get,
            },
        },
    },
);

$build->create_build_script;

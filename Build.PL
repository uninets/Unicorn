use 5.010;
use warnings;

use Module::Build;
use lib 'lib';
use Unicorn::Manager::Version;
use Getopt::Long qw(:config pass_through);

my $install = 0;
my $dist    = 0;
my @script_files = grep { -f and ! -d } glob 'script/*';
my $v = Unicorn::Manager::Version->new;

GetOptions(
    'install' => \$install,
    'dist'    => \$dist,
);

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
        'Test::More'                   => 0,
        'Moo'                          => 0,
        'File::Basename'               => 0,
        'YAML'                         => 0,
        'JSON'                         => 0,
        'Carp'                         => 0,
        'Getopt::Long'                 => 0,
        'indirect'                     => 0,
        'multidimensional'             => 0,
        'B::Hooks::OP::Check'          => 0.19, # dependency for multidimensional
        'Time::HiRes'                  => 0,
        'bareword::filehandles'        => 0,
        'Cwd'                          => 0,
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

if ($dist) {
    $build->dispatch('build');
    $build->dispatch('test');
    $build->dispatch('distmeta');
    $build->dispatch('dist');
}

if ($install) {
    $build->dispatch('build');
    $build->dispatch('test', verbose => 1);
    $build->dispatch('install');
}

$build->create_build_script();

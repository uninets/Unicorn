use strict;
use warnings;
use ExtUtils::MakeMaker;
use JSON;
use YAML;

my $provides = {
    'Unicorn::Manager'        => 'lib/Unicorn/Manager.pm',
    'Unicorn::Manager::Proc'  => 'lib/Unicorn/Manager/Proc.pm',
    'Unicorn::Manager::Types' => 'lib/Unicorn/Manager/Types.pm',
};

my $release_status = 'unstable';
my $license        = ['MIT'];

WriteMakefile(
    NAME                => 'Unicorn::Manager',
    AUTHOR              => q{Mugen Kenichi <mugen.kenichi@uninets.eu>},
    VERSION_FROM        => 'lib/Unicorn/Manager.pm',
    ABSTRACT_FROM       => 'lib/Unicorn/Manager.pm',
    INST_SCRIPT         => 'script/',
    NO_META             => 1,
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'proprietary')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => 0,
        'MooseX::Declare'    => 0.34,
        'File::Basename'     => 0,
        'Moose::Util::TypeConstraints' => 0,
        'YAML'               => 0,
        'JSON'               => 0,
        'Carp'               => 0,
        'Getopt::Long'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unicorn-*' },
);

my $mymeta_yml_str;
my $mymeta_json_str;

{
    local $/;
    open my $mymeta, '<', 'MYMETA.yml';
    $mymeta_yml_str = <$mymeta>;
    close $mymeta;
}

{
    local $/;
    open my $mymeta, '<', 'MYMETA.json';
    $mymeta_json_str = <$mymeta>;
    close $mymeta;
}

my $mymeta_json = decode_json $mymeta_json_str;
my $mymeta_yml  = Load $mymeta_yml_str;

$mymeta_json->{provides} = $provides;
$mymeta_json->{license} = $license;
$mymeta_json->{release_status} = $release_status;

$mymeta_yml->{provides} = $provides;
$mymeta_yml->{license} = $license;
$mymeta_yml->{release_status} = $release_status;

open my $meta_yml, '>', 'META.yml';
print $meta_yml Dump $mymeta_yml;
close $meta_yml;

open my $meta_json, '>', 'META.json';
print $meta_json to_json $mymeta_json, ({ pretty => 1 });
close $meta_json;


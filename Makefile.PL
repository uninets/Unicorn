use strict;
use warnings;
use ExtUtils::MakeMaker;

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
        'Carp'               => 0,
        'Getopt::Long'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Unicorn-*' },
);


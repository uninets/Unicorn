#!/usr/bin/perl

use 5.010;
use feature 'say';
use strict;
use warnings;
use autodie;
use lib 'lib';
use Unicorn::Manager::Version;
use Term::ANSIColor;
use Perl::Tidy;
use File::Find;
use File::Copy;
use File::Slurp 'edit_file';
use Getopt::Long;
use CPAN::Uploader;

my $git         = 0;
my $cpan        = 0;
my $new_version = 0;
my $debug       = 0;

my $result = GetOptions(
    'git'   => \$git,
    'cpan'  => \$cpan,
    'debug' => \$debug,
);

use Helper::Commit;

my $commit_helper = Helper::Commit->new(
    git    => $git,
    cpan   => $cpan,
    _debug => $debug,
);

$commit_helper->run;

exit 0;


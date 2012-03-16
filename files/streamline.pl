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

$git = 1 if $cpan;

sub say_ok {
    my $line = shift;
    chomp $line;

    if ( not $debug ) {
        print color 'green';
        print '  > ';
        print color 'reset';
    }
    print "$line\n";

    return 1;
}

sub say_warn {
    my $line = shift;
    chomp $line;

    if ( not $debug ) {
        print color 'yellow';
        print ' >> ';
        print color 'reset';
    }
    print "$line\n";

    return 1;
}

sub say_err {
    my $line = shift;
    chomp $line;

    if ( not $debug ) {
        print color 'red';
        print ' >> ';
        print color 'reset';
    }
    print "$line\n";

    return 1;
}

sub say_prompt {

    if ( not $debug ) {
        print color 'blue';
        print '>>> ';
        print color 'reset';
    }

    return 1;
}

sub bump_version {
    my $old_version = qx[awk '/^Version/ {print \$2}' \$(find lib/ -name Version.pm)];
    chomp $old_version;

    my $version = Unicorn::Manager::Version->get;

    my @files = qx[grep $old_version -l \$(find -iname *.p?)];

    if ( $old_version != $version ) {
        for (@files) {
            chomp;
            edit_file {s/$old_version/$version/g} $_;
        }

        $new_version = 1;
        say_ok "bumped version from $old_version to $version";

    }
    elsif ($cpan) {
        say_err "No version update. Unable to upload to CPAN";
    }
    else {
        say_warn "No version update.";
    }

    return 1;
}

sub build_meta {
    my $result = qx[perl Build.PL --meta];
    say_ok 'Updating META';
}

sub build_clean {
    if ( -f 'Build' && -x 'Build' ) {
        my $result = qx[./Build clean];
        say_warn 'cleaned up';
        say $result if $debug;
    }
    else {
        say_ok 'no need to clean';
    }

    return 1;
}

sub git_add_new_files {
    my @status = qx[git status];

    for (@status) {
        if (/.+new file:\s*(.*)/) {
            say_warn "adding $1";
            my $result = qx[git add $1];
            say $result if $debug;
        }
    }

    return 1;
}

sub git_commit {
    my @status = qx[git status];
    my $no_commit = grep { $_ ~~ /nothing to commit/ } @status;

    if ($no_commit) {
        say_ok 'nothing to commit';
    }
    else {
        say_ok 'git status:';
        say_warn $_ for @status;
        say_err 'enter commit message [finish with "."]';
        say_prompt;

        my $message = '';
        while (<>) {
            last if /^.\n/;
            $message .= $_;
        }

        say $message if $debug;

        if ($message) {
            say_ok 'commiting to git repo';
            my $result = qx[git commit -a -m '$message'];

            say $result if $debug;
        }
        else {
            say_err 'Canceled due to missing commit message.';

            exit 1;
        }
    }

    return 1;
}

sub git_push {
    my $result = qx[git push 2>&1];

    if ( $result ~~ /Everything up-to-date/ ) {
        say_ok 'Everything up-to-date.';

    }
    else {
        say_ok 'Pushed to git repo';
    }

    say $result if $debug;

    return 1;
}

sub tidy_up {
    my @files;

    find(
        sub {
            push( @files, $File::Find::name ) if ( /\.p[lm]$/i && !-d );
        },
        '.'
    );

    for (@files) {
        say_ok "Tidy up $_";
        my $destination = "$_.tidy_up";
        Perl::Tidy::perltidy(
            source      => $_,
            destination => $destination,
            perltidyrc  => 'files/perltidyrc',
        );
        move "$_.tidy_up", $_;
    }

    return 1;
}

sub build_dist {
    my $result = system 'perl Build.PL --dist 2>&1 > /dev/null';

    if ($result) {
        say_err 'Failed to build dist. Refusing to go on.';
        exit 1;
    }

    say_ok 'Built dist';
}

sub cpan_upload {

    my $version = Unicorn::Manager::Version->get;
    my ($file) = grep { -f && !-d && /$version/ } glob '*.tar.gz';

    say_err 'PAUSE password (will not echo):';
    say_prompt;

    my $pass;
    system 'stty -echo';
    while (<>) {
        $pass = $_;
        last if /\n/;
    }
    system 'stty echo';
    chomp $pass;

    my $uploader = CPAN::Uploader->new( { user => 'mugenken', password => $pass } );

    $uploader->upload_file($file);

    say_ok 'Uploaded to cpan!';
}

build_clean();
build_meta();
tidy_up();
bump_version();

if ($git) {
    git_add_new_files();
    git_commit();
    git_push();
}

if ( $cpan && $new_version ) {
    build_dist();
    cpan_upload();
}

exit 0;


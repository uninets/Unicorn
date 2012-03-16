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

sub say_pretty {
    my $line = shift;

    print color 'green';
    print ' > ';
    print color 'reset';
    print "$line\n";

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

        say_pretty "bumped version from $old_version to $version";

    }
    else {
        say_pretty "no version update";
    }

    return 1;
}

sub build_clean {
    if ( -f 'Build' && -x 'Build' ) {
        my $result = qx[./Build clean];
        say_pretty 'cleaned up';
    }
    else {
        say_pretty 'no need to clean';
    }

    return 1;
}

sub git_add_new_files {
    my @status = qx[git status];

    for (@status) {
        if (/.+new file:\s*(.*)/) {
            say_pretty "adding $1";
            my $result = qx[git add $1];
        }
    }

    return 1;
}

sub git_commit {
    say_pretty 'commiting to git repo';
    my $result = system 'git commit -a 2>&1';

    return 1;
}

sub git_push {
    say_pretty 'pushing to remote';
    my $result = qx[git push 2>&1];

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
        say_pretty "Tidy up $_";
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

build_clean();
tidy_up();
bump_version();

git_add_new_files();
git_commit();
git_push();

exit 0;


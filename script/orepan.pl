#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use 5.008001;
use OrePAN;
use OrePAN::Package::Index;
use OrePAN::Archive;

use Carp ();
use Pod::Usage qw/pod2usage/;
use Data::Dumper; sub p { print STDERR Dumper(@_) }
use Getopt::Long;
use File::Basename;
use Path::Class;
use File::Copy;
use Log::Minimal;
use LWP::UserAgent;
use File::Temp;
use File::Spec::Functions qw(catfile);

our $VERSION=$OrePAN::VERSION;

my $pauseid = 'DUMMY';
GetOptions(
    'p|pauseid=s' => sub { $pauseid = uc $_[1] },
    'd|destination=s' => \my $destination,
    'h|help' => \my $help,
    'v|version' => \my $version,
);
pod2usage(-verbose=>1) unless $destination;
if ($version) {
    print "$VERSION\n";
    exit 0;
}

my ($pkg) = @ARGV;
$pkg or pod2usage(-verbose=>1);

my $tmp;
if ($pkg =~ m{^https?://}) {
    infof("retrieve from $pkg");
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($pkg);
    die "cannot get $pkg: " . $res->status_line unless $res->is_success;
    my $filename = $res->filename;
    my ($suffix) = ($filename =~ m{(\..+)$});
    $tmp = File::Temp->new(UNLINK => 1, SUFFIX => $suffix);
    print {$tmp} $res->content;
    $tmp->flush();
    $pkg = $tmp->filename;
}
my $archive = OrePAN::Archive->new(filename => $pkg);

infof("put the archive to repository");
$destination = dir($destination);
my $authordir = $destination->subdir('authors', 'id', substr($pauseid, 0, 1), substr($pauseid, 0, 2), $pauseid);
$authordir->mkpath;
copy($pkg, $authordir->file(basename($pkg)));

infof("get package names");
my %packages = $archive->get_packages;

# make 02.packages.details.txt.gz
$destination->subdir('modules')->mkpath;
my $pkg_file = catfile($destination, 'modules', '02packages.details.txt.gz');
infof('Making %s', $pkg_file);
my $packages = -f $pkg_file ? OrePAN::Package::Index->load($pkg_file) : OrePAN::Package::Index->new();
$packages->add(
    File::Spec->catfile(
        substr( $pauseid, 0, 1 ), substr( $pauseid, 0, 2 ),
        $pauseid, basename($pkg)
    ),
    \%packages
);
$packages->save($pkg_file);

__END__

=encoding utf8

=head1 NAME

orepan.pl - yet another CPAN mirror aka DarkPAN repository manager

=head1 SYNOPSIS

    % mkdir -p /path/to/repository

    # add new module to repository directory
    % orepan.pl --destination=/path/to/repository --pause=FOO \
        Foo-0.01.tar.gz
    # retrieve from network
    % orepan.pl --destination=/path/to/repository --pause=FOO \
        https://example.com/MyModule-0.96.tar.gz

    # and use it
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION

OrePAN is yet another CPAN mirror aka DarkPAN repository manager.

orepan.pl can add a new module to DarkPAN repository. If you want remove modules, add 
many modules at once, you can use L<orepan_index.pl>

OrePAN is highly simple and B<limited>. OrePAN supports only L<App::cpanminus>. Because I'm using cpanm for daily jobs.

=head1 OPTIONS

=over 4

=item B<--destination>

Set a directory that use as DarkPAN repository

=item B<--pause>

PAUSEID, the module is copied to destination/authors/id/{substr(0,1,id)}/{substr(0,2,id)}/{id}/module

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<CPAN::Mini::Inject>, L<App::cpanminus>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
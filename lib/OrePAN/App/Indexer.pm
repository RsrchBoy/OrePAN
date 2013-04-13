package OrePAN::App::Indexer;
use strict;
use warnings;
use utf8;

use OrePAN::Package::Index;
use OrePAN::Archive;
use OrePAN::Whois;

use Carp ();
use Pod::Usage qw/pod2usage/;
use Data::Dumper; sub p { print STDERR Dumper(@_) }
use Getopt::Long;
use File::Basename;
use Path::Class;
use Log::Minimal;
use File::Find;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(mkpath);

our $VERSION='0.01';

use Class::Accessor::Lite (
    new => 1,
);

sub run {
    my $self = shift;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'r|repository=s' => \my $repository, 
        'h|help'         => \my $help,
    );
    if ($help || !$repository) {
        pod2usage(-input => $0, -verbose=>1);
    }

    my $authordir = catdir($repository, 'authors');

    mkpath(catdir($repository, 'modules'));

    my $packages_file = catfile($repository, 'modules', '02packages.details.txt.gz');
    my $packages = -f $packages_file ? OrePAN::Package::Index->load($packages_file) : OrePAN::Package::Index->new();

    my $whois = OrePAN::Whois->new();

    # Scan archives.
    find({ wanted => sub {
        my $file = $_;
        return if ! -f $file;
        return if $file !~ m!(?:\.zip|\.tar|\.tar\.gz|\.tgz)$!i;

        infof("Processing %s", $file);

        (my $parsed = $file) =~ s/^\Q$authordir\E\/id\///;
        
        my $pauseid = [split /\//, $parsed]->[2];

        my $archive = OrePAN::Archive->new(filename => $file);
        my %packages = $archive->get_packages;

        $packages->add(
            $parsed,
            \%packages
        ) or print STDERR $packages->errstr . "\n";

        $whois->add(
            id => $pauseid,
            type => 'author',
            has_cpandir => 1,
        );
    }, no_chdir => 1 }, $authordir );

    infof("Saving $packages_file");
    $packages->save($packages_file);

    my $whois_file = catfile($repository, 'authors', '00whois.xml');
    infof("Saving $whois_file");
    $whois->save("$whois_file");
}

1;


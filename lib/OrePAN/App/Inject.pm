package OrePAN::App::Inject;
use strict;
use warnings;
use utf8;

use OrePAN;
use OrePAN::Package::Index;
use OrePAN::Archive;

use Carp ();
use Pod::Usage qw/pod2usage/;
use Data::Dumper; sub p { print STDERR Dumper(@_) }
use Getopt::Long;
use File::Basename qw(basename dirname);
use File::Copy;
use Log::Minimal;
use LWP::UserAgent;
use File::Temp;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(mkpath);

our $VERSION='0.01';

sub new {
    my $class = shift;
    bless {}, $class;
}

sub run {
    my $self = shift;

    my $pauseid = 'DUMMY';

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case auto_help)]
    );
    $p->getoptions(
        'p|pauseid=s' => sub { $pauseid = uc $_[1] },
        'd|destination=s' => \my $destination,
        'h|help' => \my $help,
        'v|version' => \my $version,
    );
    pod2usage(-verbose=>1) unless $destination;
    my ($pkg) = @ARGV;

    if ($version) {
        printf "%s %s\n", basename($0), $VERSION;
        exit 0;
    }
    if ($help || !$pkg) {
        pod2usage(-input => $0, -verbose=>1);
    }

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
    my $archive = OrePAN::Archive->load($pkg);

    # Put the archive to repository
    infof("put the archive to repository");
    my $authordir = catdir($destination, 'authors', 'id', substr($pauseid, 0, 1), substr($pauseid, 0, 2), $pauseid);
    mkpath($authordir);
    copy($pkg, catfile($authordir, basename($pkg)));

    # Scan packages
    infof("get package names");
    my %packages = $archive->get_packages;

    # Make 02.packages.details.txt.gz
    mkpath(catdir($destination, 'modules'));
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
}

1;


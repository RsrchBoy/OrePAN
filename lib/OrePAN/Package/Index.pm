package OrePAN::Package::Index;

use strict;
use warnings;
use utf8;

use version;
use IO::Zlib;
use CPAN::DistnameInfo;
use File::Temp qw(:mktemp);
use Carp ();

sub new {
    my $class = shift;
    bless {
        data => { },
    }, $class;
}

sub errstr { $_[0]->{errstr} }

sub load {
    my ($class, $filename) = @_;
    Carp::croak("Missing filename") unless defined $filename;

    my $self = $class->new();

    my $fh = IO::Zlib->new($filename, 'rb');
    while (<$fh>) { # skip headers
        last unless /\S/;
    }
    while (<$fh>) {
        my ($pkg, $ver, $path) = split /\s+/, $_;
        my $dist = CPAN::DistnameInfo->new($path);
        $self->{data}->{$dist->dist} ||= {
            path    => $path,
            version => $dist->version,
            modules => {},
        };
        $self->{data}->{$dist->dist}->{modules}->{$pkg} = $ver;
    }
    close $fh;

    return $self;
}

sub add {
    my ($self, $path, $data) = @_;

    my $dist = CPAN::DistnameInfo->new($path);
    if ( $self->{data}->{$dist->dist} ) {
        my $p_version;
        my $n_version;
        eval {
            $p_version = version->parse($self->{data}->{$dist->dist}->{version});
            $n_version = version->parse($dist->version);
        };
        if ( !$@ && $n_version <= $p_version ) {
            $self->{errstr} = sprintf( "SKIP: already has newer version %s-%s: adding %s", $dist->dist, $self->{data}->{$dist->dist}->{version}, 
                   $dist->version);
            return 0;
        }
    }

    $self->{data}->{$dist->dist} = {
        path    => $path,
        version => $dist->version,
        modules => $data,
    };

    for my $distname ( keys %{$self->{data}} ) {
        next if $dist->dist eq $distname;
        for my $pkg ( keys %$data ) {
            die "'$pkg' is exists on $distname" if exists $self->{data}->{$distname}->{modules}->{$pkg}
        }
    }
    return 1;
}

# TODO need flock?
sub save {
    my ($self, $filename) = @_;
    Carp::croak("Missing filename") unless defined $filename;

    my %modules;
    for my $distname ( keys %{$self->{data}} ) {
        my $dist = $self->{data}->{$distname};
        for my $module ( keys %{$dist->{modules}} ) {
            die "'$module' is exists on $distname" if exists $modules{$module};
            $modules{$module} = [ $dist->{modules}->{$module}, $dist->{path} ];
        } 
    }

    # Because we do rename(2) atomically, temporary file must be in same
    # partion with target file.
    my $tmp = mktemp($filename . '.XXXXXX');

    my $fh = IO::Zlib->new($tmp,'wb') or die $!;
    $fh->print("File:         02packages.details.txt\n\n");
    for my $key ( sort keys %modules ) {
        $fh->print(sprintf("%s\t%s\t%s\n", $key, $modules{$key}->[0] || 'undef', $modules{$key}->[1]));
    }
    $fh->close();

    rename( $tmp, $filename )
      or Carp::croak("Cannot rename temporary file '$tmp' to @{[ $filename ]}: $!");
}

1;
__END__

=head NAME

OrePAN::Package::Index - Indexer fo 02.packages.details.gz

=head1 SEE ALSO

L<Parse::CPAN::Packages>


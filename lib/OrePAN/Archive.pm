package OrePAN::Archive;

use strict;
use warnings;
use utf8;
use YAML::Tiny ();
use JSON ();
use List::MoreUtils qw/any/;
use Log::Minimal;
use File::Basename;
use File::Temp qw(tempdir);
use Path::Class;
use File::Which qw(which);  
use Cwd qw/realpath getcwd/;
use File::pushd;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir rel2abs);

sub load {
    my ($class, $filename) = @_;

    bless {
        filename => rel2abs($filename),
    }, $class;
}

sub filename { $_[0]->{filename} }

sub load_meta {
    my $self = shift;

    my @files = @{$self->files};
    if ( my ($json) = grep /META.json$/, @files ) {
        JSON::decode_json($json->slurp);
    }
    elsif ( my ($yml) = grep /META\.yml/, @files ) {
        my $dat = eval {
            # json format yaml
            my $data = $yml->slurp;
            YAML::Tiny::Load($data) || JSON::decode_json($data);
        };
        return $dat;
    }
    else {
        return undef;
    }
}


sub files {
    my $self = shift;

    my @files;
    dir($self->extracted_directory)->recurse(callback => sub {
        my $path = shift;
        return if $path->is_dir;
        push @files, $path;
    });
    return \@files;
}


sub extracted_directory {
    my $self = shift;

    if ($self->filename =~ m!\.zip$!i) {
        return $self->unzip($self->filename)
    } else {
        return $self->untar($self->filename);
    }
}


sub tmpdir {
    my $self = shift;
    $self->{tmpdir} ||= tempdir(CLEANUP => 0);
}

sub _parse_version($) {
    my $parsefile = shift;
    my $inpod = 0;
    my @pkgs;

    local $/ = "\x0a";
    local $_;
    my $fh = $parsefile->openr;

    LOOP: while (<$fh>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        chop;
        next if /^\s*(if|unless)/;
        last if ( /\b__(?:END|DATA)__\b/ && $parsefile !~ m!\.PL$! ); # PL files may well have code after __DATA__
        if ( m{^ \s* package \s+ (\w[\w\:\']*) (?: \s+ (v?[0-9._]+) \s*)? (?:\s+)?;  }x ) {
            push @pkgs, [$1, $2];
        }
        elsif ( m{(?<!\\) ([\$*]) (([\w\:\']*) \bVERSION)\b (.*) =}x ) {
            my $sigil = $1;
            my $varname = $2;
            my $package = $3 || '';
            my $rest = $4;
            $package =~ s!::$!!;

            # do not match comparing version number
            # like: $Text::Diff::VERSION >= 0.03
            if ($rest =~ /[=><]\s*$/) {
                next LOOP;
            }

            # Copy from ExtUtils::MM_Unix
            my $eval = qq{
                package 
                  ExtUtils::MakeMaker::_version;
                no strict;
                BEGIN { eval {
                    # Ensure any version() routine which might have leaked
                    # into this package has been deleted.  Interferes with
                    # version->import()
                    undef *version;
                    require version;
                    "version"->import;
                } }

                local $sigil$varname;
                \$$varname=undef;
                do {
                    $_
                };
                \$$varname;
            };
            local $^W = 0;
            my $version = eval($eval);  ## no critic
            warn $eval if $@;
            warnf("Could not eval '$eval' in $parsefile: $@") if $@;
            if ( ! ref($version) ) {
                $version = eval { version->new($version) };
            }
            next if !$version;

            push @pkgs, [$package, $version] if $package;
            $pkgs[-1]->[1] = $version if @pkgs;
        }
        elsif (/^\s*__END__/) {
            last;
        }
    }
    return if @pkgs == 0;

    my $basename  = fileparse("$parsefile");
    $basename =~ s/\..+$//;
    my @candidates = sort { !$a->[1] <=> !$b->[1] }
        grep { $_->[0] =~ m/($basename)$/ || $basename eq 'version' } @pkgs;
    return @{$candidates[0]} if @candidates;
    return;
}

sub get_packages {
    my ($self) = @_;

    my $meta = $self->load_meta;
    unless ($meta) {
        warnf("Cannot load META file from archive");
    }
    $meta ||= +{};

    my $ignore_dirs = $meta->{no_index} && $meta->{no_index}->{directory} ? $meta->{no_index}->{directory} : [];
    my @ignore_dirs = ref $ignore_dirs ? @$ignore_dirs : [$ignore_dirs];
    push @ignore_dirs, "t","xt", 'contrib', 'examples','inc','share','private', 'blib';
    infof("files");
    my $archive = $self->extracted_directory;
    my @files = @{$self->files()};
    infof("ok files");
    my %res;
    for my $file (@files) {
        my $quote = quotemeta($archive);
        next if any { $file =~ m{^$quote/$_/} } @ignore_dirs;
        next if $file !~ /\.pm(?:\.PL)?$/;
        infof("parsing: $file");
        my ( $pkg, $ver) = _parse_version($file);
        infof("parsed: %s version: %s", $pkg || 'unknown', $ver || 'none');
        if ($pkg) {
            $res{$pkg} = defined $ver ? "$ver" : "";
        }
    }
    for my $pkg (keys %{ $meta->{provides} || {} }) {
        require version;
        my $ver = do {
            my $version = $meta->{provides}->{$pkg}->{version};
            defined $version ? eval { version->new($version) } : undef;
        };
        infof("provides: %s version: %s", $pkg, $ver || 'none');
        $res{$pkg} = defined $ver ? "$ver" : "";
    }
    return wantarray ? %res : \%res;
}

sub untar {
    my $self = shift;
    my $tarfile = shift;
    if ( my $tar = which('tar') ) {
        my $tempdir = $self->tmpdir;
        my $guard = pushd($tempdir);
        
        my $xf = "xf";
        my $ar = $tarfile =~ /bz2$/ ? 'j' : 'z';
        my($root, @others) = `$tar tf$ar $tarfile`
            or return die "Bad archive $tarfile";
        chomp $root;
        $root =~ s{^(.+?)/.*$}{$1};
        debugf("cwd: %s, tar: $tar $xf$ar $tarfile", getcwd);
        system "$tar $xf$ar $tarfile";
        return catdir($tempdir, $root) if -d $root;
        die "Bad archive: $tarfile";
    }
    else {
        die "can't find tar";
    }
}

sub unzip {
    my $self = shift;
    my $zipfile = shift;
    if ( my $unzip = which('unzip') ) {
        my $tempdir = $self->tmpdir;
        my $guard = pushd($tempdir);

        my(undef, $root, @others) = `$unzip -t $zipfile`
            or return undef;
        chomp $root;
        $root =~ s{^\s+testing:\s+(.+?)/\s+OK$}{$1};
        system "$unzip $zipfile";
        return catdir($tempdir, $root) if -d $root;        
    }
    else {
        die "can't find unzip";
    }
}

sub DESTROY {
    my $self = shift;
    rmtree($self->tmpdir) if $self->{tmpdir};
}

1;
__END__

=head1 NAME

OrePAN::Archive - Parse CPAN module tar ball and get informations

=head1 DESCRIPTION

This module parse CPAN module tar ball and get informations.

=head1 METHODS

TBD

=head1 SEE ALSO

L<Dist::Metadata>

L<MyCPAN::Indexer>

L<CPAN::ParseDistribution>


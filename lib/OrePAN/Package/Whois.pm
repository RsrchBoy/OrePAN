package OrePAN::Package::Whois;

use strict;
use warnings;
use utf8;
use Mouse;

has filename => (
    is       => 'ro',
    required => 1,
);

has data => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

no Mouse;

sub add {
    my ($self, %data) = @_;
    $self->{data} .= <<"EOS";
  <cpanid>
    <id>$data{cpanid}</id>
    <type>author</type>
    <has_cpandir>1</has_cpandir>
  </cpanid>
EOS
}

sub save {
    my ($self, ) = @_;
    my $cont = $self->data;
    chomp $cont;
    open my $fh, '>', $self->filename or die $!;
    print $fh <<"EOS";
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois>
$cont
</cpan-whois>
EOS
    close $fh;
}

1;
__END__

=head1 NAME

OrePAN::Package::Whois - authors/00whois.xml

=head1 DESCRIPTION

This is a generator for C<authors/00whois.xml>.

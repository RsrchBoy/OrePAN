package CPAN::Whois;

use strict;
use warnings;
use utf8;

use Moo;

has _authors => (
    is      => 'ro',
    default => sub { +[] },
);

no Moo;

use CPAN::Whois::Author;

sub authors {
    my $self = shift;
    map { CPAN::Whois::Author->new($_) } @{$self->{_authors}};
}

sub add {
    my ($self, %data) = @_;

    for my $key (qw(id type has_cpandir)) {
        unless (defined $data{$key}) {
            Carp::croak("Missing mandatory parameter: $key");
        }
    }

    push @{$self->{_authors}}, \%data;
}

sub as_xml {
    my ($self) = @_;

    my $buf = '';
       $buf .= qq{<?xml version="1.0" encoding="UTF-8"?>\n};
       $buf .= "<cpan-whois>\n";
       $buf .= $_->as_xml for $self->authors;
       $buf .= "</cpan-whois>\n";
       $buf;
}

sub save {
    my ($self, $filename) = @_;
    Carp::croak("Missing mandatory parameter: filename") unless @_==2;

    my $content = $self->as_xml;

    open my $fh, '>', $filename
        or Carp::croak("Cannot open '$filename' for writing: $!");
    print {$fh} $content;
    close $fh;
}

1;
__END__

=head1 NAME

CPAN::Whois - authors/00whois.xml

=head1 DESCRIPTION

This is a generator for C<authors/00whois.xml>.


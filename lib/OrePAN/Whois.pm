package OrePAN::Whois;

use strict;
use warnings;
use utf8;

use OrePAN::Whois::Author;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub authors {
    my $self = shift;
    map { OrePAN::Whois::Author->new($_) } @{$self->{_authors}};
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

OrePAN::Whois - authors/00whois.xml

=head1 SYNOPSIS

    use OrePAN::Whois;

    my $whois = OrePAN::Whois->new();
    $whois->add(id => 'DANKOGAI', type => 'author', has_cpandir => 1);
    $whois->save('00whois.xml');

=head1 DESCRIPTION

This is a generator for C<authors/00whois.xml>.

=head1 METHODS

=over 4

=item my $whois = OrePAN::Whois->new();

Create new instance of this class.

=item $whois->add(%args)

=item $whois->as_xml()

Create XML string from the object.

=item $whois->save($filename);

Save the content of whois xml to C<$filename>.

=back


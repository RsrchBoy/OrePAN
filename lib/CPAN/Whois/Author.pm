package CPAN::Whois::Author;
use strict;
use warnings;
use utf8;

use Moo;

has [qw(id type has_cpandir)]  => (
    is => 'rw',
);

no Moo;

sub as_xml {
    my $self = shift;

    my $buf = "  <cpanid>\n";
    for my $key (qw(id type has_cpandir)) {
        if (defined $self->$key) {
            $buf .= sprintf "    <%s>%s</%s>\n", $key, $self->$key, $key;
        }
    }
    $buf .= "  </cpanid>\n";

    return $buf;
}

1;
__END__

=head1 NAME

CPAN::Whois::Author - Author entry for 00whois.xml

=head1 DESCRIPTION

This is a author entry object for C<00whois.xml>.

=head1 METHODS

=over 4

=item id

=item type

=item has_cpandir

=back


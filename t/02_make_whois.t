use strict;
use warnings;
use utf8;
use Test::More;
use CPAN::Whois;
use File::Temp;
use IO::File;

my $tmp = File::Temp->new();

# make whois
{
    my $whois = CPAN::Whois->new();
    my $pauseid = "DUMMY";
    $whois->add(id => $pauseid, type => 'author', has_cpandir => 1);
    $whois->save($tmp->filename);
}

# and read it.
{
    my $fh = IO::File->new($tmp->filename, 'r') or die $!;
    my $got = do { local $/; undef $/; <$fh> };
    is $got, <<"...";
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois>
  <cpanid>
    <id>DUMMY</id>
    <type>author</type>
    <has_cpandir>1</has_cpandir>
  </cpanid>
</cpan-whois>
...
}

done_testing;

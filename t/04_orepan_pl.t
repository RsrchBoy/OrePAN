use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);

my $tmp = tempdir(CLEANUP => 1);
is(system(
    $^X,
    '-Ilib',
    'script/orepan.pl',
    '--pauseid=XXX',
    "--destination=$tmp",
    't/dummy-cpan/Foo-Bar-0.01.tar.gz'
), 0);

done_testing;


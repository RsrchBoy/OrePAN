use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile catdir);

my $tmp = tempdir(CLEANUP => 1);
mkpath(catfile($tmp, 'authors/id/X/XX/XXX'));
copy('t/dummy-cpan/Foo-Bar-0.01.tar.gz', catfile($tmp, 'authors/id/X/XX/XXX'));
is(system(
    $^X,
    '-Ilib',
    'script/orepan_index.pl',
    "--repository=$tmp",
), 0);

done_testing;


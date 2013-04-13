#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.008001;

use OrePAN::App::Inject;

OrePAN::App::Inject->new()->run();

__END__

=encoding utf8

=head1 NAME

orepan.pl - yet another CPAN mirror aka DarkPAN repository manager

=head1 SYNOPSIS

    % mkdir -p /path/to/repository

    # add new module to repository directory
    % orepan.pl --destination=/path/to/repository --pause=FOO \
        Foo-0.01.tar.gz
    # retrieve from network
    % orepan.pl --destination=/path/to/repository --pause=FOO \
        https://example.com/MyModule-0.96.tar.gz

    # and use it
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION

OrePAN is yet another CPAN mirror aka DarkPAN repository manager.

orepan.pl can add a new module to DarkPAN repository. If you want remove modules, add 
many modules at once, you can use L<orepan_index.pl>

OrePAN is highly simple and B<limited>. OrePAN supports only L<App::cpanminus>. Because I'm using cpanm for daily jobs.

=head1 OPTIONS

=over 4

=item B<--destination>

Set a directory that use as DarkPAN repository

=item B<--pause>

PAUSEID, the module is copied to destination/authors/id/{substr(0,1,id)}/{substr(0,2,id)}/{id}/module

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<CPAN::Mini::Inject>, L<App::cpanminus>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

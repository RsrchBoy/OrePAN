#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.008001;
use OrePAN::App::Index;

OrePAN::App::Index->new()->run();

__END__

=encoding utf8

=head1 NAME

orepan_index.pl - yet another CPAN mirror aka DarkPAN index builder

=head1 SYNOPSIS

    # make directory
    % mkdir -p /path/to/repository/{modules,authors}
    # copy CPAN mouldes to the directory
    % cp MyModule-0.03.tar.gz /path/to/repository/authors/id/A/AB/ABC/

    # make index file
    % orepan_index.pl --repository=/path/to/repository

    # remove module and recreate index
    % rm /path/to/repository/authors/id/A/AB/ABC/MyModule-0.04.tar.gz
    % orepan_index.pl --repository=/path/to/repository

    # and use it
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION

OrePAN is yet another CPAN mirror aka DarkPAN repository manager.

orepan_index.pl is CPAN mirror aka DarkPAN index builder. 
orepan_index.pl parses all tarballs in specified repository directory, and makes 02packages.txt.gz file.

You can use the directory aka DarkPAN with `cpanm --mirror`.

If you want to add other mouldes to repository in one command, you can use L<orepan.pl>

=head1 OPTIONS

=over 4

=item B<--repository>

Set a directory that use as DarkPAN repository

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

Masahiro Nagano E<lt>kazeburo AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<CPAN::Mini::Inject>, L<App::cpanminus>, L<OrePAN>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

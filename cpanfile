requires 'perl', '5.008001';

requires 'CPAN::DistnameInfo';
requires 'Cwd';
requires 'File::Basename';
requires 'File::Find';
requires 'File::Temp';
requires 'File::Which';
requires 'IO::Zlib';
requires 'JSON', '2.27';
requires 'LWP::UserAgent';
requires 'List::MoreUtils';
requires 'Log::Minimal', '0.02';
requires 'Mouse';
requires 'Path::Class';
requires 'YAML::Tiny';
requires 'File::pushd';
requires 'Getopt::Long';
requires 'Mouse::Util::TypeConstraints';
requires 'Pod::Usage';
requires 'version';
requires 'Class::Accessor::Lite', 0.05;

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'Test::More', '0.96';
};

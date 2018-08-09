use strict;
use warnings;

# Ported from Dist::Zilla::Plugin::CheckLib (C) 2014 Karen Etheridge

use Path::Tiny;
my $code = path('t', 'dist_zilla_plugin_ffi_checklib.t')->slurp_utf8;

$code =~ s/'MakeMaker'/'ModuleBuild'/g;
$code =~ s/ExtUtils::MakeMaker/Module::Build/g;
$code =~ s/Makefile.PL/Build.PL/g;
$code =~ s/# build prereqs go here/build => \{ requires => \{ 'Module::Build' => ignore \} \},/;

eval $code;
die $@ if $@;

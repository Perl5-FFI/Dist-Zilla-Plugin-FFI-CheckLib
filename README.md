# Dist::Zilla::Plugin::FFI::CheckLib [![Build Status](https://secure.travis-ci.org/Perl5-FFI/Dist-Zilla-Plugin-FFI-CheckLib.png)](http://travis-ci.org/Perl5-FFI/Dist-Zilla-Plugin-FFI-CheckLib)

FFI::CheckLib alternative to Dist::Zilla::Plugin::CheckLib

# SYNOPSIS

In your `dist.ini`:

    [FFI::CheckLib]
    lib = zmq

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin that modifies the `Makefile.PL` or
`Build.PL` in your distribution to check for a dynamic library [FFI::Raw](https://metacpan.org/pod/FFI::Raw) (or
similar) can access; uses [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) to perform the check.

If the library is not available, the program exits with a status of zero,
which will result in a NA result on a CPAN test reporter.

Derived from [Dist::Zilla::Plugin::CheckLib](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckLib) (see ["AUTHOR"](#author)) -- look there
for non-FFI applications.

# CONFIGURATION OPTIONS

All options are as documented in [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib):

## `lib`

The name of a single dynamic library (for example, `zmq`). 
Can be used more than once.

[FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) will prepend `lib` and append an appropriate dynamic library
suffix as needed.

## `symbol`

A symbol that must be found. Can be used more than once.

## `systempath`

The system search path to use (instead of letting [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib) determine
paths). Can be used more than once.

## `libpath`

Additional path to search for libraries. Can be used more than once.

## `recursive`

If set to true, directories specified in `libpath` will be searched
recursively.

Defaults to false.

# SEE ALSO

- [FFI::CheckLib](https://metacpan.org/pod/FFI::CheckLib)
- [Devel::CheckLib](https://metacpan.org/pod/Devel::CheckLib) and [Dist::Zilla::Plugin::CheckLib](https://metacpan.org/pod/Dist::Zilla::Plugin::CheckLib)
- [Devel::AssertOS](https://metacpan.org/pod/Devel::AssertOS) and [Dist::Zilla::Plugin::AssertOS](https://metacpan.org/pod/Dist::Zilla::Plugin::AssertOS)

# AUTHORS

- Jon Portnoy <avenj@cobaltirc.org>
- Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jon Portnoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

use strict; use warnings;
package Dist::Zilla::Plugin::FFI::CheckLib;

use Moose;
with
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::InstallTool',
  'Dist::Zilla::Role::PrereqSource',
;

use Scalar::Util 'blessed';
use namespace::autoclean;

my @list_options = qw(lib libpath symbol);
sub mvp_multivalue_args { @list_options }

has $_ => (
  isa => 'ArrayRef[Str]',
  lazy => 1,
  default => sub { [] },
  traits => ['Array'],
  handles => { $_ => 'elements' },
) for @list_options;

my @string_options = qw(debug);
has \@string_options => (
  is => 'ro', isa => 'Str',
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  $config->{+__PACKAGE__} = {
      ( map { $_ => [ $self->$_ ] } @list_options ),
      ( map { $_ => $self->$_ } @string_options ),
  };

  $config
};

sub register_prereqs
{
  my $self = shift;
  $self->zilla->register_prereqs(
    {
      phase => 'configure',
      type  => 'requires',
    },
    'FFI::CheckLib' => '0.03',
  );
}

my %files;
sub munge_files
{
  my $self = shift;

  my @mfpl = grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } @{ $self->zilla->files };
  for my $mfpl (@mfpl)
  {
      $self->log_debug('munging ' . $mfpl->name . ' in file gatherer phase');
      $files{$mfpl->name} = $mfpl;
      $self->_munge_file($mfpl);
  }
  return;
}

sub setup_installer
{
  my $self = shift;

  my @mfpl = grep { $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } @{ $self->zilla->files };

  $self->log_fatal('No Makefile.PL or Build.PL was found. [FFI::CheckLib] should appear in dist.ini after [MakeMaker] or variant!') unless @mfpl;

  for my $mfpl (@mfpl)
  {
      next if exists $files{$mfpl->name};
      $self->log_debug('munging ' . $mfpl->name . ' in setup_installer phase');
      $self->_munge_file($mfpl);
  }
  return;
}

sub _munge_file
{
  my ($self, $file) = @_;

  my $orig_content = $file->content;
  $self->log_fatal('could not find position in ' . $file->name . ' to modify!')
      if not $orig_content =~ m/use strict;\nuse warnings;\n\n/g;

  my $pos = pos($orig_content);

  # build a list of tuples: field name => string
  my @options = (
      (map {
          my @stuff = map { '\'' . $_ . '\'' } $self->$_;
          @stuff
              ? [ $_ => @stuff > 1 ? ('[ ' . join(', ', @stuff) . ' ]') : $stuff[0] ]
              : ()
      } @list_options),
      (map {
          defined $self->$_
              ? [ $_ => '\'' . $self->$_ . '\'' ]
              : ()
      } @string_options),
  );

  $file->content(
      substr($orig_content, 0, $pos)
      . "# inserted by " . blessed($self) . ' ' . ($self->VERSION || '<self>') . "\n"
      . "use FFI::CheckLib;\n"
      . "check_lib_or_exit(\n"
      . join('',
              map { '    ' . $_->[0] . ' => ' . $_->[1] . ",\n" } @options
          )
      . ");\n\n"
      . substr($orig_content, $pos)
  );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::FFI::CheckLib - FFI::CheckLib alternative to Dist::Zilla::Plugin::CheckLib

=head1 SYNOPSIS

In your F<dist.ini>:

    [FFI::CheckLib]
    lib = zmq

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that modifies the F<Makefile.PL> or
F<Build.PL> in your distribution to check for a dynamic library L<FFI::Raw> (or
similar) can access. Uses L<FFI::CheckLib>.

If the library is not available, the program exits with a status of zero,
which will result in a NA result on a L<CPAN Testers|cpantesters.org> machine.

Derived from L<Dist::Zilla::Plugin::CheckLib> (see L</AUTHOR>) -- look there
for non-FFI applications.

=for Pod::Coverage mvp_multivalue_args register_prereqs munge_files setup_installer

=head1 CONFIGURATION OPTIONS

All options are as documented in L<FFI::CheckLib>:

=head2 C<lib>

A string with the name of a single library name. Can be used more than once.

L<FFI::CheckLib> will prepend C<lib> and append an appropriate dynamic library
suffix as needed.

=head2 C<libpath>

Additional path to search for libraries. Can be used more than once.

=head2 C<debug>

If true, emit information during processing that can be used for debugging.
B<Note>: as this is an arbitrary string that is inserted directly into
F<Makefile.PL> or F<Build.PL>, this can be any arbitrary expression,
for example:

    [FFI::CheckLib]
    debug = $ENV{AUTOMATED_TESTING} || $^O eq 'MSWin32'

=head1 SEE ALSO

=over 4

=item *

L<FFI::CheckLib>

=item *

L<Devel::CheckLib> and L<Dist::Zilla::Plugin::CheckLib>

=item *

L<Devel::AssertOS> and L<Dist::Zilla::Plugin::AssertOS>

=item *

L<Devel::CheckBin> and L<Dist::Zilla::Plugin::CheckBin>

=back

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

This module is adapted directly from L<Dist::Zilla::Plugin::CheckLib>,
copyright (c) 2014 by Karen Etheridge (CPAN: ETHER).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

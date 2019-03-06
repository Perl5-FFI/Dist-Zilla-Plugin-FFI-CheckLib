package Dist::Zilla::Plugin::FFI::CheckLib;

use strict;
use warnings;

# ABSTRACT: FFI::CheckLib alternative to Dist::Zilla::Plugin::CheckLib
# VERSION

use Moose;
with
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::InstallTool',
  'Dist::Zilla::Role::PrereqSource',
;

use namespace::autoclean;

my @list_options = qw/
  lib
  libpath
  symbol
  systempath
  verify
/;
sub mvp_multivalue_args { @list_options }

has $_ => (
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] },
  traits  => ['Array'],
  handles => { $_ => 'elements' },
) for @list_options;

has recursive => (
  is      => 'rw',
  lazy    => 1,
  default => sub { 0 },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  $config->{+__PACKAGE__} = +{ 
    (map {; $_ => [ $self->$_ ] } @list_options),
    recursive => $self->recursive,
  };

  $config
};

sub register_prereqs {
  my ($self) = @_;
  $self->zilla->register_prereqs( +{
      phase => 'configure',
      type  => 'requires',
    },
    'FFI::CheckLib' => '0.11',
  );
}

my %files;
sub munge_files {
  my ($self) = @_;

  my @mfpl = grep 
    {; $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } 
      @{ $self->zilla->files };

  for my $mfpl (@mfpl) {
    $self->log_debug('munging ' . $mfpl->name . ' in file gatherer phase');
    $files{ $mfpl->name } = $mfpl;
    $self->_munge_file($mfpl);
  }

  ()
}

sub setup_installer {
  my ($self) = @_;

  my @mfpl = grep 
    {; $_->name eq 'Makefile.PL' or $_->name eq 'Build.PL' } 
      @{ $self->zilla->files };

  unless (@mfpl) {
    $self->log_fatal(
      'No Makefile.PL or Build.PL was found.'
      .' [FFI::CheckLib] should appear in dist.ini'
      .' after [MakeMaker] or variant!'
    );
  }

  for my $mfpl (@mfpl) {
    next if exists $files{ $mfpl->name };
    $self->log_debug('munging ' . $mfpl->name . ' in setup_installer phase');
    $self->_munge_file($mfpl);
  }

  ()
}

sub _munge_file {
  my ($self, $file) = @_;

  my $orig_content = $file->content;
  $self->log_fatal('could not find position in ' . $file->name . ' to modify!')
    unless $orig_content =~ m/use strict;\nuse warnings;\n\n/g;
  my $pos = pos($orig_content);

  my @options = map {;
    my @stuff = map {; '\'' . $_ . '\'' } $self->$_;
    @stuff ? 
      [ 
        $_ => @stuff > 1 ? ('[ ' . join(', ', @stuff) . ' ]') : $stuff[0]
      ] : ()
  } grep !/^verify$/, @list_options, ( $self->recursive ? 'recursive' : () );

  my @verify = map { s/^\|//; $_ } $self->verify;

  $file->content(
      substr($orig_content, 0, $pos)
    . "# inserted by " . blessed($self)
    . ' ' . ($self->VERSION || '<self>') . "\n"
    . "use FFI::CheckLib;\n"
    . "check_lib_or_exit(\n"
    . join('', map {; ' 'x2 . $_->[0] . ' => ' . $_->[1] . ",\n" } @options )
    . (@verify ? join("\n", map { ' 'x2 . $_ } 'verify => sub {', (map { ' 'x2 . $_ } @verify), '},')."\n" : '')
    . ");\n\n"
    . substr($orig_content, $pos)
  );
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

In your F<dist.ini>:

 [FFI::CheckLib]
 lib = zmq

=head1 DESCRIPTION

B<NOTE>: This module has been merged into C<Dist-Zilla-Plugin-FFI> and this
repository is no longer used for development.

This is a L<Dist::Zilla> plugin that modifies the F<Makefile.PL> or
F<Build.PL> in your distribution to check for a dynamic library L<FFI::Platypus> (or
similar) can access; uses L<FFI::CheckLib> to perform the check.

If the library is not available, the program exits with a status of zero,
which will result in a NA result on a CPAN test reporter.

This module is adapted directly from Dist::Zilla::Plugin::CheckLib, copyright (c) 2014 by Karen Etheridge (CPAN: ETHER).
Look there for XS modules.


=head1 CONFIGURATION OPTIONS

All options are as documented in L<FFI::CheckLib>:

=head2 C<lib>

The name of a single dynamic library (for example, C<zmq>). 
Can be used more than once.

L<FFI::CheckLib> will prepend C<lib> and append an appropriate dynamic library
suffix as needed.

=head2 C<symbol>

A symbol that must be found. Can be used more than once.

=head2 C<systempath>

The system search path to use (instead of letting L<FFI::CheckLib> determine
paths). Can be used more than once.

=head2 C<libpath>

Additional path to search for libraries. Can be used more than once.

=head2 C<recursive>

If set to true, directories specified in C<libpath> will be searched
recursively.

Defaults to false.

=head2 C<verify>

The verify function body to use.  For each usage, is one line of the function
body.  You can prefix with the pipe C<|> character to get proper indentation.

 verify = | my($name, $libpath) = @_;
 verify = | my $ffi = FFI::Platypus->new;
 verify = | $ffi->lib($libpath);
 verify = | my $f = $ffi->function('foo_version', [] => 'int');
 verify = | if($f) {
 verify = |   return $f->call() >= 500; # we accept version 500 or better
 verify = | } else {
 verify = |   return;
 verify = | }

If you use any modules, such as L<FFI::Platypus> in this example, be sure that
you declare them as configure requires.

=head1 SEE ALSO

=over 4

=item *

L<FFI::CheckLib>

=item *

L<Devel::CheckLib> and L<Dist::Zilla::Plugin::CheckLib>

=item *

L<Devel::AssertOS> and L<Dist::Zilla::Plugin::AssertOS>

=back

=cut

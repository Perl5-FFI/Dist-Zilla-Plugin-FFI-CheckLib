use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Dist::Zilla::Plugin::FFI::CheckLib;
use Path::Tiny;

# Ported from Dist::Zilla::Plugin::CheckLib (C) 2014 Karen Etheridge

my @tests = (
  { name => 'EUMM', dzil_installer => 'MakeMaker',       installer => 'ExtUtils::MakeMaker', script_PL => 'Makefile.PL', },
  { name => 'MB',   dzil_installer => 'ModuleBuild',     installer => 'Module::Build',       script_PL => 'Build.PL',    },
  { name => 'MBT',  dzil_installer => 'ModuleBuildTiny', installer => 'Module::Build::Tiny', script_PL => 'Build.PL',    },
);

my $pattern = <<PATTERN;
use strict;
use warnings;

# inserted by Dist::Zilla::Plugin::FFI::CheckLib @{[ Dist::Zilla::Plugin::FFI::CheckLib->VERSION || '<self>' ]}
use FFI::CheckLib;
check_lib_or_exit(
    lib => [ 'iconv', 'jpeg' ],
    libpath => 'additional_path',
    symbol => [ 'foo', 'bar' ],
    systempath => 'system',
    recursive => '1',
);
PATTERN

foreach my $test (@tests)
{

  subtest $test->{name} => sub {

    if($test->{name} eq 'MBT')
    {
      plan skip_all => 'Test requires Dist::Zilla::Plugin::ModuleBuildTiny 0.07'
        unless eval { require Dist::Zilla::Plugin::ModuleBuildTiny; Dist::Zilla::Plugin::ModuleBuildTiny->VERSION(0.007) };
    }

    
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ 'GatherDir' ],
                    [ 'MetaConfig' ],
                    [ $test->{dzil_installer} ],
                    [ 'FFI::CheckLib' => {
                            lib => [ qw(iconv jpeg) ],
                            libpath => 'additional_path',
                            symbol => [ qw(foo bar) ],
                            systempath => 'system',
                            recursive => 1,
                        },
                    ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'nothing exploded',
    );

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child($test->{script_PL});
    ok(-e $file, "@{[ $test->{script_PL} ]} created");
    
    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated file');

    like(
        $content,
        qr/\Q$pattern\E$/m,
        "code inserted into @{[ $test->{script_PL} ]}",
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            prereqs => superhashof({
                configure => {
                    requires => {
                        'FFI::CheckLib' => '0.11',
                        $test->{installer} => ignore,    # populated by [installer]
                    },
                },
            }),
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::FFI::CheckLib',
                        config => {
                            'Dist::Zilla::Plugin::FFI::CheckLib' => superhashof({
                                lib => [ 'iconv', 'jpeg' ],
                                libpath => [ 'additional_path' ],
                                symbol => [ 'foo', 'bar' ],
                                systempath => [ 'system' ],
                                recursive => 1,
                            }),
                        },
                        name => 'FFI::CheckLib',
                        version => ignore,
                    },
                ),
            }),
        }),
        'prereqs are properly injected for the configure phase',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;
    
    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
  }
}

done_testing;

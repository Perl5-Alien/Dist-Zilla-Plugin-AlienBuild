use Test2::Bundle::Extended;
use Test::DZil;
use Dist::Zilla::Plugin::AlienBuild;
use JSON::PP qw( decode_json );
use List::Util qw( first );

{ package Foo::Config; our $VERSION = '1.00'; $INC{'Foo/Config.pm'} = __FILE__ }

subtest 'mm' => sub {

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo1' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Alien-Foo1' },
        [ 'GatherDir'  => {} ],
        [ 'MakeMaker'  => {} ],
        [ 'MetaJSON'   => {} ],
        [ 'AlienBuild' => {} ],
      ),
    },
  });
  
  $tzil->build;

  foreach my $file (@{ $tzil->files })
  {
    note "[@{[ $file->name ]}]";
    note $file->content;
  }

  my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);
  
  is(
    $meta->{dynamic_config},
    T(),
    'dynamic config is set in META.json',
  );
  
  is(
    $meta->{prereqs}->{configure}->{requires},
    hash {
      field 'Alien::Build::MM'    => T();
      field 'Foo::Config'         => '0.55';
      field 'ExtUtils::MakeMaker' => E();
      etc;
    },
    'configure prereqs',
  );

  is(
    $meta->{prereqs}->{build}->{requires},
    hash {
      field 'Alien::Build::MM' => T();
      field 'Foo::Build' => '0.01';
      etc;
    },
    'build prereqs',
  );
  
  my $makefile_pl = (first { $_->name eq 'Makefile.PL' } @{ $tzil->files })->content;
  
  like $makefile_pl, qr{Alien::Build::MM}, 'reference to AB::MM';

};

subtest 'mb' => sub {

  skip_all 'Test requires Alien::Build::MB'
    unless eval q{ use Alien::Build::MB; 1 };

  my $tzil = Builder->from_config({ dist_root => 'corpus/Alien-Foo1' }, {
    add_files => {
      'source/dist.ini' => simple_ini(
        { name => 'Alien-Foo1' },
        [ 'GatherDir'   => {} ],
        [ 'ModuleBuild' => {} ],
        [ 'MetaJSON'    => {} ],
        [ 'AlienBuild'  => {} ],
      ),
    },
  });
  
  $tzil->build;
  
  foreach my $file (@{ $tzil->files })
  {
    note "[@{[ $file->name ]}]";
    note $file->content;
  }

  my $meta = decode_json((first { $_->name eq 'META.json' } @{ $tzil->files })->content);

  is(
    $meta->{prereqs}->{configure}->{requires},
    hash {
      field 'Alien::Build::MB'    => T();
      field 'Foo::Config'         => '0.55';
      etc;
    },
    'configure prereqs',
  );

  is(
    $meta->{prereqs}->{build}->{requires},
    hash {
      field 'Alien::Build::MB' => T();
      field 'Foo::Build' => '0.01';
      etc;
    },
    'build prereqs',
  );
  
  my($build_pl) = first { $_->name eq 'Build.PL' } @{ $tzil->files };
  
  like $build_pl->content, qr/Alien::Build::MB/, 'seems to work?';
  
  my($mb_plugin) = first { $_->isa('Dist::Zilla::Plugin::ModuleBuild') } @{ $tzil->plugins };

  is( $mb_plugin->mb_class, 'Alien::Build::MB', 'mb_class was set' );
  
};


done_testing;



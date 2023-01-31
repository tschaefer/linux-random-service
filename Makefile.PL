#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'ABSTRACT'   => 'Harvest random bytes web service.',
  'AUTHOR'     => 'Tobias Schaefer <github@blackox.org>',
  'DISTNAME'   => 'Linux-Random-Service',
  'EXE_FILES'  => ['bin/rnd-service'],
  'META_MERGE' => {
    resources => {
      'license'    => 'https://dev.perl.org/licenses',
      'homepage'   => 'https://github.com/tschaefer/linux-random-service',
      'repository' => 'https://github.com/tschaefer/linux-random-service.git',
    }
  },
  'NAME'      => 'Linux::Random::Service',
  'PREREQ_PM' => {
    'Linux::Random'          => '>=0.01',
    'Mojolicious'            => '>=9.31',
    'Minion'                 => '>=10.25',
    'Mojo::Log::Role::Color' => '>=0.04',
    'Mojo::Pg'               => '>=4.27',
    'Readonly'               => '>=2.05',
  },
  'VERSION_FROM' => 'lib/Linux/Random/Service.pm',
  'clean'        => {FILES    => 'Linux-Random-Service-*'},
  'dist'         => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl',) : ()),
);

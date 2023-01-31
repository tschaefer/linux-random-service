package Mock::Linux::Random::Service;

use Mojo::Base 'Mojolicious';

use Mojo::Pg;
use Mojo::URL;

use Test::Mojo;

has pg  => sub { Mojo::Pg->new(shift->url->to_unsafe_string); };
has url => sub { Mojo::URL->new($ENV{RANDOM_SERVICE_TEST_DB})->query([search_path => 'random_test']); };

sub setup {
  my $self = shift;

  $self->pg->db->query('DROP SCHEMA IF EXISTS random_test CASCADE');
  $self->pg->db->query('CREATE SCHEMA random_test');

  my $cfg = {
    postgres => $self->url->to_unsafe_string,
    secrets  => ['test_s3cret'],
    root     => '/random',
    log      => {level => $ENV{HARNESS_IS_VERBOSE} ? 'trace' : 'fatal'},
  };

  my $t = Test::Mojo->new('Linux::Random::Service' => $cfg);
  $t->ua->max_redirects(10);

  return $t;
}

sub teardown {
  my $self = shift;

  $self->pg->db->query('DROP SCHEMA IF EXISTS random_test CASCADE');

  return;
}

sub DESTROY { return shift->teardown; }

1;

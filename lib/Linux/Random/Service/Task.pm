package Linux::Random::Service::Task;
use Mojo::Base 'Minion::Job';

use Linux::Random qw(rnd_get_random);

sub run {
  my ($self, $bytes, $device) = @_;

  $device //= 'urandom';
  my $random = rnd_get_random($bytes, '/dev/' . $device, 'base64');

  return $self->finish($random);
}

1;

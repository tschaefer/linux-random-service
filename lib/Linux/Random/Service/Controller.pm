package Linux::Random::Service::Controller;
use Mojo::Base 'Mojolicious::Controller';

use Readonly;
use Scalar::Util qw(looks_like_number);

Readonly my $TASK => 'Linux::Random::Service::Task';

sub enqueue {
  my $self = shift;

  my $validation = $self->validation;
  $validation->required('bytes')->num(128, 10 * 1024 * 1024);
  $validation->optional('device')->in('random', 'urandom');
  for my $param (@{$validation->failed}) {
    return $self->render(
      json   => {$param => $self->param($param), error => 'requested param ' . $param . ' is invalid'},
      status => 400
    );
  }

  my $id = $self->minion->enqueue(randomness => [$validation->param('bytes'), $validation->param('device')]);
  return $self->render(json => {id => $id}, status => 201);
}

sub result {
  my $self = shift;

  my $job = $self->_job;
  return if ref $job ne $TASK;

  return $self->render(json => {id => $job->id, error => 'job not finished'}, status => 406)
    unless $job->info->{finished};
  return $self->render(json => {id => $job->id, result => $job->info->{result}});
}

sub status {
  my $self = shift;

  my $job = $self->_job;
  return if ref $job ne $TASK;

  my $info = $job->info;
  delete $info->{result};
  delete $info->{id};

  return $self->render(json => {id => $job->id, info => $info});
}

sub _job {
  my $self = shift;

  my $id = $self->param('id');
  return $self->render(json => {id => $id, error => 'job id is invalid'}, status => 400)
    if !looks_like_number($id) || $id <= 0;

  my $job = eval { $self->minion->job($id) };
  return $self->render(json => {id => $id, error => 'job not found'}, status => 404) if ref $job ne $TASK;

  return $job;
}

1;

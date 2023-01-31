package Linux::Random::Service::Plugin;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $config) = @_;

  $self->setup_render_hook($app, $config);
  $self->setup_notification($app, $config);

  return;
}

sub setup_render_hook {
  my ($self, $app, $config) = @_;

  return $app->hook(
    before_render => sub {
      my ($client, $args) = @_;

      return if !$args->{template};
      return if $args->{template} !~ m{not_found};

      $args->{json}   = {error => 'no such endpoint', method => $client->req->method, url => $client->req->url};
      $args->{status} = 404;
    }
  );
}

sub setup_notification {
  my ($self, $app, $config) = @_;
  return if !$app->config->{redis};

  require Mojo::Redis;
  require Mojo::JSON;

  $app->helper(redis   => sub { return state $redis   = Mojo::Redis->new($app->config->{redis}->{url}); });
  $app->helper(channel => sub { return state $channel = $app->config->{redis}->{channel}; });

  $app->minion->on(
    worker => sub {
      my ($minion, $worker) = @_;
      $worker->on(dequeue => \&_dequeue);
    }
  );

  return;
}

sub _dequeue {
  my ($worker, $job) = @_;

  my $id  = $job->id;
  my $app = $worker->minion->app;

  for my $event (qw(start finished failed)) {
    $job->on($event => sub { _notify->($app, $id, $event); });
  }

  return;
}

sub _notify {
  my ($app, $id, $status) = @_;

  my $redis   = $app->redis;
  my $channel = $app->channel;

  $redis->pubsub->notify($channel, Mojo::JSON::encode_json([$id, $status]));

  return;
}

1;

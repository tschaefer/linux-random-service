package Linux::Random::Service;
use Mojo::Base 'Mojolicious';

our $VERSION = '20230131.0';

sub startup {
  my $self = shift;

  my $configfile = $ENV{RANDOM_SERVICE_CONFIG};
  $self->plugin(Config => {file => $configfile});

  $self->secrets($self->config->{secrets});
  $self->_routes;

  $self->plugin(Minion => {Pg => $self->config->{postgres}});
  $self->plugin('Linux::Random::Service::Plugin');

  $self->minion->add_task(randomness => 'Linux::Random::Service::Task');
  $self->_admin;

  $self->helper(log => \&_log);

  return;
}

sub _log {
  my $self = shift;

  return state $log = Mojo::Log->with_roles("+Color")->new(level => $self->config->{log}->{level} // 'trace');
}

sub _admin {
  my $self = shift;
  return if !$self->config->{admin};

  my $admin_path = sprintf "%s/admin", $self->config->{root};

  my $under = $self->routes->under(
    $admin_path => sub {
      my $app = shift;

      my $credentials = sprintf "%s:%s", $app->config->{admin}->{user}, $app->config->{admin}->{password};
      return 1 if $app->req->url->to_abs->userinfo eq $credentials;

      $app->res->headers->www_authenticate('Basic');
      $app->render(text => 'Authentication required!', status => 401);

      return;
    }
  );

  $self->plugin('Minion::Admin' => {route => $under});

  return;
}

sub _routes {
  my $self = shift;

  my $routes = $self->routes->any($self->config->{root});
  $routes->get('/' => sub { shift->render(json => {}, status => 204) });

  $routes = $routes->any('/job');
  $routes->get('/' => sub { shift->render(json => {}, status => 204) });

  $routes->get('/result/:id')->to('controller#result')->name('random_job_result');
  $routes->get('/status/:id')->to('controller#status')->name('random_job_status');
  $routes->post('/enqueue')->to('controller#enqueue')->name('random_job_enqueue');

  return;
}

1;

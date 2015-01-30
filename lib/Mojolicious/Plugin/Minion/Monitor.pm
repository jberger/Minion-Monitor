package Mojolicious::Plugin::Minion::Monitor;

use Mojo::Base 'Mojolicious::Plugin';

use Carp;

sub register {
  my ($plugin, $app, $opts) = @_;
  my $path = $opts->{path} or croak 'A "path" argument is required';

  my $monitor = Mojo::Server->new->build_app('Minion::Monitor')->parent($app);

  $app->routes->route($path)->detour(app => $monitor);
}

1;


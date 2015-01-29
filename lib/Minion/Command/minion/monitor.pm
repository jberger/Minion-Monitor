package Minion::Command::minion::monitor;

use Mojo::Base 'Mojolicious::Command::daemon';

use Minion::Monitor;

use Mojolicious::Command::daemon;
use Mojolicious::Routes;

has description => 'Monitor your minion workers and tasks via a web interface';

has usage => '';

sub run {
  my ($command, @args) = @_;

  # replace the app's router and then mount the monitor to /

  my $parent = $command->app;
  my $r = Mojolicious::Routes->new;
  $parent->routes($r);

  my $monitor = Mojo::Server->new->build_app('Minion::Monitor');
  $monitor->parent($parent);

  $r->route('/')->detour(app => $monitor);

  $command->SUPER::run(@args);
}

1;


package Minion::Command::minion::monitor;

use Mojo::Base 'Mojolicious::Command::daemon';

use Minion::Monitor;

use Mojolicious::Routes;

has description => 'Monitor your minion workers and tasks via a web interface';

has usage => sub {
  my $usage = shift->SUPER::usage;
  $usage =~ s/daemon/minion monitor/g;
  return $usage;
};

sub run {
  my $command = shift;

  # replace the app's router and then mount the monitor to /
  $command->app
    ->routes(Mojolicious::Routes->new)
    ->plugin('Minion::Monitor' => { path => '/' });

  $command->SUPER::run(@_);
}

1;


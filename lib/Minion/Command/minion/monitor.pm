package Minion::Command::minion::monitor;

use Mojo::Base 'Mojolicious::Command';

use Mojolicious::Command::daemon;

use Mojolicious::Routes;

has description => 'Monitor your minion workers and tasks via a web interface';

has usage => '';

sub run {
  my ($command, @args) = @_;

  my $app = $command->app;

  my $r = Mojolicious::Routes->new;
  $app->routes($r);

  my $api = $r->under('/api');

  my $api_list = $api->under(sub {
    my $c = shift;
    $c->stash('limit'  => $c->param('limit')  || 100);
    $c->stash('offset' => $c->param('offset') || 0);
    return 1;
  });

  $api->any('/stats' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->stats);
  });

  $api->any('/job/:id' => sub {
    my $c = shift;
    my $id = $c->stash('id');
    $c->render(json => $c->app->minion->backend->job_info($c->stash('id')));
  });

  $api_list->any('/jobs' => sub {
    my $c = shift;
    my $options = {
      state => $c->param('state'),
      task  => $c->param('task'),
    };
    $c->render(json => $c->app->minion->backend->list_jobs(@{$c->stash}{qw/offset limit/}, $options));
  });
  
  $api->any('/worker/:id' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->worker_info($c->stash('id')));
  });

  $api_list->any('/workers' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->list_workers(@{$c->stash}{qw/offset limit/}));
  });

  $command->Mojolicious::Command::daemon::run(@args);
}

1;


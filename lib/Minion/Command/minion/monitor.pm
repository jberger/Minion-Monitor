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

  $api->get('/stats' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->stats);
  });

  $api->get('/job/:id' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->job_info($c->stash('id')));
  });

  $api->delete('/job/:id' => sub {
    my $c = shift;
    my $success = $c->app->minion->backend->remove_job($c->stash('id'));
    $c->render(json => {success => $success ? \1 : \0});
  });

  $api->patch('/job/:id' => sub {
    my $c = shift;
    my $success = $c->app->minion->backend->retry_job($c->stash('id'));
    $c->render(json => {success => $success ? \1 : \0});
  });

  $api_list->get('/jobs' => sub {
    my $c = shift;
    my $options = {
      state => $c->param('state'),
      task  => $c->param('task'),
    };
    $c->render(json => $c->app->minion->backend->list_jobs(@{$c->stash}{qw/offset limit/}, $options));
  });
  
  $api->get('/worker/:id' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->worker_info($c->stash('id')));
  });

  $api_list->get('/workers' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->list_workers(@{$c->stash}{qw/offset limit/}));
  });

  $command->Mojolicious::Command::daemon::run(@args);
}

1;


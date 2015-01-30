package Minion::Monitor;

use Mojo::Base 'Mojolicious';

use Mojo::Home;
use File::Spec ();

use constant DEBUG => $ENV{MINION_MONITOR_DEBUG};

sub home {
  require Minion::Command::minion::monitor;
  my $home = $INC{'Minion/Command/minion/monitor.pm'};
  $home =~ s/\.pm$//;
  $home = File::Spec->rel2abs($home);
  Mojo::Home->new($home);
};

has parent => sub {
  require Mojo::Server;
  my $parent = Mojo::Server->new->build_app('Mojo::HelloWorld');
  $parent->plugin(Minion => {File => 'minion.db'});
  return $parent;
};


sub startup {
  my $app = shift;
  $app->helper(minion => sub { shift->app->parent->minion });

  my $r = $app->routes;

  my $home = $app->home;
  $app->log->debug("Home directory: $home") if DEBUG;

  $app->static->paths([$home->rel_dir('public')]);
  $app->renderer->paths([$home->rel_dir('templates')]);
  if (DEBUG) {
    $app->log->debug('Static file directories: ' . $app->dumper($app->static->paths));
    $app->log->debug('Templates directories: ' . $app->dumper($app->renderer->paths));
  }

  $r->get('/' => sub { shift->redirect_to('jobs') });

  $r->get('/job/:id' => {template => 'job'})->name('job');
  $r->get('/jobs' => {template => 'jobs'})->name('jobs');

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
  })->name('api_stats');

  $api->get('/tasks' => sub {
    my $c = shift;
    $c->render(json => [sort keys %{$c->app->minion->tasks}]);
  });

  $api->post('/job' => sub {
    my $c = shift;
    my $minion = $c->app->minion;
    my $input = $c->req->json || {};

    my $task = $input->{task};
    unless ($minion->tasks->{$task}) {
      return $c->render(json => {success => \0}, status => 404);
    }

    my $args = $input->{args} || [];
    my @valid = qw/delay priority/;
    my %options; @options{@valid} = @{$input}{@valid};

    my $job = $minion->enqueue($task, $args, \%options);
    $c->render(json => {success => \1, id => $job});
  });

  $api->get('/job/:id' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->job_info($c->stash('id')));
  })->name('api_job');

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
    my $jobs = $c->app->minion->backend->list_jobs(@{$c->stash}{qw/offset limit/}, $options);
    for my $job (@$jobs) {
      my $id = $job->{id};
      $job->{url} = {
        api => $c->url_for(api_job => id => $id),
        web => $c->url_for(job => id => $id),
      };
    }
    $c->render(json => $jobs);
  })->name('api_jobs');

  $api->get('/worker/:id' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->worker_info($c->stash('id')));
  });

  $api_list->get('/workers' => sub {
    my $c = shift;
    $c->render(json => $c->app->minion->backend->list_workers(@{$c->stash}{qw/offset limit/}));
  });
}

1;


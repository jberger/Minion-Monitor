use Mojolicious::Lite;

plugin 'Minion' => { File => app->home->rel_file('minion.db') };

app->minion->add_task(sleep => sub { sleep pop });

app->start;


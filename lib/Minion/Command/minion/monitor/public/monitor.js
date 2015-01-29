(function(rivets, routes) {
  'use strict';

  console.group("Minion Monitor");

  rivets.formatters.json = function(input) { return JSON.stringify(input); };
  rivets.formatters.date = function(value){
    return moment.unix(value).format('MMM DD hh:mm:ss.SSS a');
  };

  var page_limit = 10;
  var jobs = {
    list: [],
    filter: {
      state:    '',
      all:      function(){ return this.state === ''; },
      active:   function(){ return this.state === 'active'; },
      inactive: function(){ return this.state === 'inactive'; },
      finished: function(){ return this.state === 'finished'; },
      failed:   function(){ return this.state === 'failed'; }
    },
    stats: {},
    refreshing: false,
    page: 1,
    pages: function(){
      var f = this.filter.state || 'all';
      var c = this.stats[f+'_jobs'];
      return Math.ceil(c / page_limit);
    }
  };

  var job = {details: {}, url: ''};

  var refresh = function() {
    console.group("Function refresh");
    jobs.refreshing = true;

    var query = {
      limit:  page_limit,
      offset: page_limit * (jobs.page - 1)
    };

    if (jobs.filter.state) {
      query.state = jobs.filter.state;
    }

    get_jobs(query);
    get_stats();
    console.groupEnd("Function refresh");
  };

  var get_jobs = function(query) {
    console.group("Function get_jobs");
    $.get(routes.jobs, query, function(data) {
      console.group("$.get(" + routes.jobs + ")");
      jobs.list = data;
      jobs.refreshing = false; //TODO time with stats call too.

      console.info("jobs.list: ", jobs.list);
      console.groupEnd("$.get(" + routes.jobs + ")");
    });
    console.groupEnd("Function get_jobs");
  };

  var get_stats = function() {
    console.group("Function get_stats");
    $.get(routes.stats, function(data) {
      console.group("$.get(" + routes.stats + ")");
      jobs.stats = data;
      jobs.stats.all_jobs = data.active_jobs + data.inactive_jobs + data.finished_jobs + data.failed_jobs;

      console.info('jobs.stats: ', jobs.stats);
      console.groupEnd("$.get(" + routes.stats + ")");
    });
    console.groupEnd("Function get_stats");
  };

  var set_filter = function(filter) {
    console.group("Function set_filter");
    jobs.filter.state = filter;
    jobs.page = 1;
    refresh();
    console.groupEnd("Function set_filter");
  };

  var show_job = function(link) {
    console.group("Function show_job");
    var url = $(link).attr('api');
    job.url = url;

    $.get(url, function(data) {
      job.details = data;
      $('#job-modal').modal('show');
    });
    console.groupEnd("Function show_job");
  };

  var modify_job = function(type) {
    console.group("Function modify_job");

    var actions = {
      Retry: 'PATCH',
      Remove: 'DELETE'
    };

    $.ajax({
      url: job.url,
      type: actions[type],
      success: function(){ alert(type + ' successful'); refresh() }
    });
    console.groupEnd("Function modify_job");
  };

  var move_page = function(dir) {
    console.group("Function move_page");
    if (dir === -1 && jobs.page === 1) { return; }
    if (dir === 1  && jobs.page === jobs.pages()) { return; }
    jobs.page = jobs.page + dir;
    refresh();
    console.groupEnd("Function move_page");
  };

  $(function() {
    rivets.bind($('tbody'),       {jobs: jobs});
    rivets.bind($('.menu'),       {jobs: jobs});
    rivets.bind($('#refresh'),    {jobs: jobs});
    rivets.bind($('#pagination'), {jobs: jobs});
    rivets.bind($('#job-modal'),  {job: job});

    $('body').on('click', '.func_set_filter', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_set_filter");

      var filter = $(this).data('filter');
      set_filter(filter);
      console.groupEnd("Event click on .func_set_filter");
    });

    $('body').on('click', '.func_show_job', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_show_job");

      show_job(this);
      console.groupEnd("Event click on .func_show_job");
    });

    $('body').on('click', '.func_refresh', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_refresh");

      refresh();
      console.groupEnd("Event click on .func_refresh");
    });

    $('body').on('click', '.func_page_left', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_page_left");

      move_page(-1);
      console.groupEnd("Event click on .func_page_left");
    });

    $('body').on('click', '.func_page_right', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_page_right");

      move_page(1);
      console.groupEnd("Event click on .func_page_right");
    });

    $('body').on('click', '.func_remove_job', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_remove_job");

      modify_job('Remove');
      console.groupEnd("Event click on .func_remove_job");
    });

    $('body').on('click', '.func_retry_job', function(evt) {
      evt.preventDefault();
      console.group("Event click on .func_retry_job");

      modify_job('Retry');
      console.groupEnd("Event click on .func_retry_job");
    });

    refresh();
  });

  console.groupEnd("Minion Monitor");
}(rivets, routes));

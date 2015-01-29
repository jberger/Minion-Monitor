(function(rivets) {
  'use strict';

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

  rivets.bind($('tbody'),       {jobs: jobs});
  rivets.bind($('.menu'),       {jobs: jobs});
  rivets.bind($('#refresh'),    {jobs: jobs});
  rivets.bind($('#pagination'), {jobs: jobs});

  var job = {details: {}, url: ''};
  rivets.bind($('#job-modal'), {job: job});

  var refresh = function() {
    jobs.refreshing = true;

    var query = {
      limit:  page_limit,
      offset: page_limit * (jobs.page - 1)
    };

    if (jobs.filter.state) {
      query.state = jobs.filter.state;
    }

    get_jobs();

    get_stats();
  };

  var get_jobs = function() {
    $.get(routes.jobs, query, function(data) {
      jobs.list = data;
      jobs.refreshing = false; //TODO time with stats call too.
    });
  };

  var get_stats = function() {
    $.get(routes.stats, function(data) {
      jobs.stats = data;
      jobs.stats.all_jobs = data.active_jobs + data.inactive_jobs + data.finished_jobs + data.failed_jobs;
    });
  };

  var set_filter = function(filter) {
    jobs.filter.state = filter;
    jobs.page = 1;
    refresh();
  };

  var show_job = function(link) {
    var url = $(link).attr('api');
    job.url = url;

    $.get(url, function(data) {
      job.details = data;
      $('#job-modal').modal('show');
    });
  };

  var modify_job = function(type) {
    var actions = {
      Retry: 'PATCH',
      Remove: 'DELETE'
    };

    $.ajax({
      url: job.url,
      type: actions[type],
      success: function(){ alert(type + ' successful'); refresh() }
    });
  };

  var move_page = function(dir) {
    if (dir === -1 && jobs.page === 1) { return; }
    if (dir === 1  && jobs.page === jobs.pages()) { return; }
    jobs.page = jobs.page + dir;
    refresh();
  };

  $(function() {
    $('body').on('click', '.func_set_filter', function(evt) {
      evt.preventDefault();

      var filter = $(this).data('filter');
      set_filter(filter);
    });

    $('body').on('click', '.func_show_job', function(evt) {
      evt.preventDefault();

      show_job(this);
    });

    $('body').on('click', '.func_refresh', function(evt) {
      evt.preventDefault();

      refresh();
    });

    $('body').on('click', '.func_page_left', function(evt) {
      evt.preventDefault();

      move_page(-1);
    });

    $('body').on('click', '.func_page_right', function(evt) {
      evt.preventDefault();

      move_page(1);
    });

    $('body').on('click', '.func_remove_job', function(evt) {
      evt.preventDefault();

      modify_job('Remove');
    });

    $('body').on('click', '.func_retry_job', function(evt) {
      evt.preventDefault();

      modify_job('Retry');
    });

    refresh();
  });
}(rivets));

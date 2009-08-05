/* ----------------------------------------------------------------------------
 * Log Search Server JS
 * by John Tajima
 * requires jQuery 1.3.2
 * ----------------------------------------------------------------------------
 */


var Search = {
  search_form  : 'search',                        // domId of the form
  search_fields: [ 'term1', 'term2', 'term3' ],   // domIds of search term fields
  file_list    : 'file-list',                     // domId of select for logfiles
  logfiles     : {},                              // hash of log files
  past_params  : null,                            // recent request
  url          : '/perform',                      

  // initialize Search form
  // { 'grep': [ log, files, for, grep], 'tail': [ 'log', 'files', 'for', 'tail']}
  init: function(logfiles, params) {
    this.logfiles    = logfiles;
    this.past_params = params;
    
    this.bind_grep_tool();
    this.bind_tail_tool();

    if (!this.past_params) return; // return if no prev settings, nothing to set

    // set tool selector
    (this.past_params['tool'] == 'grep') ? $('#grep-label').trigger('click') :  $('#tail-tool').trigger('click'); 
    
    // set log file selector
    $('#'+this.file_list).val(this.past_params['file']);

    // set search fields
    jQuery.each(this.search_fields, function(){
      $('#'+this).val(this.past_params[this]);
    });
  },

  
  // bind change grep tool
  bind_grep_tool: function() {
    $('#grep-tool').bind('change', function(e){
      var newlist = ""
      jQuery.each(Search.logfiles['grep'], function(){
        newlist += "<option value='" + this + "'>" + this + "</option>\n"
      });
      $('#'+Search.file_list).html(newlist);
    });
    // watch clicking label as well
    $('#grep-label').bind('click', function(e){ 
      $('#grep-tool').attr('checked', 'checked').val('grep').trigger('change');
    });
  },
  
  
  // bind change tail tool
  bind_tail_tool: function() {
    $('#tail-tool').bind('change', function(e){
      var newlist = ""
      jQuery.each(Search.logfiles['tail'], function(){
        newlist += "<option value='" + this + "'>" + this + "</option>\n"
      });
      $('#'+ Search.file_list).html(newlist);
    });
    // watch clicking label as well
    $('#tail-label').bind('click', function(e){ 
      $('#tail-tool').attr('checked', 'checked').val('tail').trigger('change');
    });
  },
  
  
  // clears the terms fields
  clear: function() {
    jQuery.each(this.search_fields, function(){
      $('#'+this).val("");
    });
  },
  
  // gathers form elements and submits to proper url
  submit: function() {
    var form   = '#'+this.search_form;
    var params = $(form).serialize();
    var query  = this.url + "?" + params
    $('#results').attr('src', query);
  }
};


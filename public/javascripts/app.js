/* ----------------------------------------------------------------------------
 * Log Search Server JS
 * by John Tajima
 * requires jQuery 1.3.2
 * ----------------------------------------------------------------------------
 */


var Search = {
  search_fields: [ 'term1', 'term2', 'term3' ],
  search_form: 'search',    // domId of the form
  file_list: 'file-list',   // domId of select for logfiles
  logfiles: [],
  past_params: null,

  // initialize Search form
  // { 'grep': [ log, files, for, grep], 'tail': [ 'log', 'files', 'for', 'tail']}
  init: function(logfiles, params) {
    this.logfiles    = logfiles;
    this.past_params = params;
    
    this.bind_grep_tool();
    this.bind_tail_tool();

    if (!this.past_params) {
      return;
    }

      
    // set tool
    if (this.past_params['tool'] == 'grep') {
      $('#grep-tool').attr('checked', 'checked').val('grep').trigger('change'); 
    } else {
      $('#tail-tool').attr('checked', 'checked').val('tail').trigger('change'); 
    }

    // set file
    $('#'+this.file_list).val(this.past_params['file']);

    // set search fields
    $('#term1').val(this.past_params['term1']);
    $('#term2').val(this.past_params['term2']);
    $('#term3').val(this.past_params['term3']);    
  },

  
  // update grep tool list
  bind_grep_tool: function() {
    $('#grep-tool').bind('change', function(e){
      var newlist = ""
      jQuery.each(Search.logfiles['grep'], function(){
        newlist += "<option value='" + this + "'>" + this + "</option>\n"
      });
      $('#'+Search.file_list).html(newlist);
    });
  },
  
  
  // update tail tool list
  bind_tail_tool: function() {
    $('#tail-tool').bind('change', function(e){
      var newlist = ""
      jQuery.each(Search.logfiles['tail'], function(){
        newlist += "<option value='" + this + "'>" + this + "</option>\n"
      });
      $('#'+ Search.file_list).html(newlist);
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
    var form = '#'+this.search_form;
    var params = $(form).serialize();
    // console.log("params are "+params);
    // return false;
    //$(form).submit();
    var url = "/perform?" + params
    $('#results').attr('src', url);
  }
};


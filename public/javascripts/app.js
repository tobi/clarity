/* ----------------------------------------------------------------------------
 * Log Search Server JS
 * by John Tajima
 * requires jQuery 1.3.2
 * ----------------------------------------------------------------------------
 */


var Search = {
  search_form  : 'search',                        // domId of the form
  resultsId    : 'results',
  search_fields: [ 'term1', 'term2', 'term3' ],   // domIds of search term fields
  file_list    : 'file-list',                     // domId of select for logfiles
  logfiles     : {},                              // hash of log files
  past_params  : null,                            // recent request
  url          : '/perform',  
  scroll_fnId  : null,                    

  // initialize Search form
  // { 'grep': [ log, files, for, grep], 'tail': [ 'log', 'files', 'for', 'tail']}
  init: function(logfiles, params) {
    this.logfiles    = logfiles;
    this.past_params = params;
    
    this.bind_grep_tool();
    this.bind_tail_tool();
    this.bind_options();
    
    if (!this.past_params) return; // return if no prev settings, nothing to set

    // set tool selector
    (this.past_params['tool'] == 'grep') ? $('#grep-label').trigger('click') :  $('#tail-tool').trigger('click'); 
    
    // set log file selector
    $('#'+this.file_list).val(this.past_params['file']);

    // set search fields
    jQuery.each(this.search_fields, function(){
      $('#'+this).val(Search.past_params[this]);
    }); 
    
    // advanced options usd?
    // time was set - so show advanced options
    if ((this.past_params['sh']) || (this.past_params['eh'])) {
      this.showAdvanced();
      if (this.past_params['sh']) {
        jQuery.each(['sh', 'sm', 'ss'], function(){ $('#'+this).val(Search.past_params[this])  });        
      }
      if (this.past_params['eh']) {
        jQuery.each(['eh', 'em', 'es'], function(){ $('#'+this).val(Search.past_params[this])  });        
      }      
    }
       
  },

  // bind option selectors
  bind_options: function() {
    $('#auto-scroll').bind('change', function(){
        Search.autoScroll(this.checked);
    });
    $('#auto-scroll').attr('checked', true).trigger('change'); // by default, turn on
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
  
  showAdvanced: function() {
    $('#enable-advanced').hide();
    $('#disable-advanced').show();
    $('#advanced-options').show();
  },
  
  hideAdvanced: function() {
    this.clearAdvanced();
    $('#enable-advanced').show();
    $('#disable-advanced').hide();
    $('#advanced-options').hide();
  },
  
  clearAdvanced: function() {
    $('#advanced-options input').val("");
  },
  
  // gathers form elements and submits to proper url
  submit: function() {
    $('#'+this.search_form).submit();
    $('#'+this.resultsId).html("Sending new query..."); 
  },
  
  //
  // Misc utitilies
  //

  autoScroll: function(enabled) {    
    if (enabled == true) {
      if (this.scroll_fnId) 
        return; // already running

      //console.log("scroll ON!")
      window._currPos = 0; // init pos
      this.scroll_fnId = setInterval ( function(){
        if (window._currPos < document.height) {
          window.scrollTo(0, document.height);
          window._currPos = document.height;
        }
      }, 250 );
    } else {
      if (!this.scroll_fnId)
        return; 
      //console.log("scroll off")
      if (this.scroll_fnId) {
        clearInterval(this.scroll_fnId);
        window._currPost = 0;
        this.scroll_fnId = null;
      }
    }    
  }
  
};


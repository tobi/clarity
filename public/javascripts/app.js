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
  past_params  : null,                            // recent request
  url          : '/perform',  
  scroll_fnId  : null,                    

  // initialize Search form
  init: function(params) {
    this.past_params = params;
    this.bind_options();
    
    if (!this.past_params) return; // return if no prev settings, nothing to set

    // init tool selector
    (this.past_params['tool'] == 'grep') ? $('#grep-tool').attr('checked', 'checked') :  $('#tail-tool').attr('checked', 'checked'); 
    
    // init log file selector
    $('#'+this.file_list).val(this.past_params['file']);

    // init search fields
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

    document.body.onwheel = function(e) {
      if (e.deltaY < 0) { // disable auto-scroll when scrolling backward
        $('#auto-scroll').attr('checked', false).change();
      }
    };

  },

  // bind option selectors
  bind_options: function() {
    $('#auto-scroll').bind('change', function(){
        Search.autoScroll(this.checked);
    });
    $('#auto-scroll').attr('checked', true).trigger('change'); // by default, turn on
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
    $('.advanced-options').show();
  },
  
  hideAdvanced: function() {
    this.clearAdvanced();
    $('#enable-advanced').show();
    $('#disable-advanced').hide();
    $('.advanced-options').hide();
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
      if (this.scroll_fnId) return; // already running

      //console.log("scroll ON!")
      window._currPos = 0; // init pos
      this.scroll_fnId = setInterval(function() {
        $('#results')[0].scrollIntoView({ block: "end" });
      }, 100);
    } else {
      if (!this.scroll_fnId) return; 
      //console.log("scroll off")
      if (this.scroll_fnId) {
        clearInterval(this.scroll_fnId);
        window._currPost = 0;
        this.scroll_fnId = null;
      }
    }    
  }
  
};


class CommandBuilder

  # parameter names
  TERM_PARAMS = ['term1', 'term2', 'term3']
  FILE_PARAM  = 'file'
  TOOL_PARAM  = 'tool'

  def self.build_command(params)
    "echo #{sanitize_query(params['q'])}"
  end
  
  def self.sanitize_query(query_string)
    return if query_string.blank?
    query = Regexp.escape(query_string).gsub(/'/, "").gsub(/"/, "")
  end
  
  def self.validate_params(params)
    raise InvalidParameterError, "Must have at least 1 search term parameter" if TERM_PARAMS.all? {|term| params[term].blank? }
    raise InvalidParameterError, "Log file parameter not supplied" if params[FILE_PARAM].blank?
    raise InvalidParameterError, "Tool parameter not supplied" if params[TOOL_PARAM].blank?
    true
  end
  
  # return array of search terms in order
  def self.get_search_terms(params)
    TERM_PARAMS.map {|term| params.fetch(term, nil) }.reject {|term| term.blank? }.compact
  end
  
  def self.get_file(params)
    params.fetch(FILE_PARAM)
  end
end
class CommandBuilder

  def self.build_command(params)
    "echo #{sanitize_query(params['q'])}"
  end
  
  def self.sanitize_query(query_string)
    return if query_string.blank?
    query = Regexp.escape(query_string).gsub(/'/, "").gsub(/"/, "")
  end
  
end
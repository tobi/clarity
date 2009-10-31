module BasicAuth

  def decode_credentials(request)
    Base64.decode64(request).split.last
  end
    
  def user_name_and_password(request)
    decode_credentials(request).split(/:/, 2)
  end
  
  def authentication_data
    headers = @http_headers.split("\000")
    auth_header = headers.detect {|head| head =~ /Authorization: / }
    header = auth_header.nil? ? "" : auth_header.split("Authorization: Basic ").last    
    return (user_name_and_password(header) rescue ['', ''])
  end
  
  def authenticate!(http_header)
    raise NotAuthenticatedError unless authenticate(http_header)
  end
  
end
module BasicAuth

  def decode_credentials(request)
    Base64.decode64(request).split.last
  end
    
  def user_name_and_password(request)
    decode_credentials(request).split(/:/, 2)
  end
  
  def authenticate(http_header)
    headers = http_header.split("\000")
    auth_header = headers.detect {|head| head =~ /Authorization: / }
    auth_request = auth_header.nil? ? "" : auth_header.split("Authorization: Basic ").last    
    if auth_request.blank?
      false
    else
      user_name_and_password(auth_request) == [USERNAME, PASSWORD]
    end
  end
  
  def authenticate!(http_header)
    raise NotAuthenticatedError unless authenticate(http_header)
  end
  
end
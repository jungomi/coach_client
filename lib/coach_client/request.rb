module CoachClient
  # Request methods for the HTTP verbs GET, PUT, POST, DELETE.
  module Request
    # The default header.
    DEFAULT_HEADER = { accept: :json }

    # GET request to the RESTful service.
    #
    # @param [String] url
    # @param [String] username
    # @param [String] password
    # @param [Hash] header
    # @return [CoachClient::Response]
    def self.get(url, username: nil, password: nil, **header)
      header.merge!(DEFAULT_HEADER)
      begin
        response = RestClient::Request.execute(method: :get, url: url,
                                               user: username,
                                               password: password,
                                               headers: header)
      rescue RestClient::ResourceNotFound => e
        raise CoachClient::NotFound, e.message
      rescue RestClient::Unauthorized => e
        raise CoachClient::Unauthorized, e.message
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end

    # PUT request to the RESTful service.
    #
    # @param [String] url
    # @param [String] username
    # @param [String] password
    # @param [String] payload required
    # @param [Hash] header
    # @return [CoachClient::Response]
    def self.put(url, username: nil, password: nil, payload:, **header)
      header.merge!(DEFAULT_HEADER)
      begin
        response = RestClient::Request.execute(method: :put, url: url,
                                               user: username,
                                               password: password,
                                               payload: payload,
                                               headers: header)
      rescue RestClient::ResourceNotFound => e
        raise CoachClient::NotFound, e.message
      rescue RestClient::Unauthorized => e
        raise CoachClient::Unauthorized, e.message
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation, 'Incomplete Information'
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end

    # POST request to the RESTful service.
    #
    # @param [String] url
    # @param [String] username
    # @param [String] password
    # @param [String] payload required
    # @param [Hash] header
    # @return [CoachClient::Response]
    def self.post(url, username: nil, password: nil, payload:, **header)
      header.merge!(DEFAULT_HEADER)
      begin
        response = RestClient::Request.execute(method: :post, url: url,
                                               user: username,
                                               password: password,
                                               payload: payload,
                                               headers: header)
      rescue RestClient::ResourceNotFound => e
        raise CoachClient::NotFound, e.message
      rescue RestClient::Unauthorized => e
        raise CoachClient::Unauthorized, e.message
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation, 'Incomplete Information'
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end

    # DELETE request to the RESTful service.
    #
    # @param [String] url
    # @param [String] username
    # @param [String] password
    # @param [Hash] header
    # @return [CoachClient::Response]
    def self.delete(url, username: nil, password: nil, **header)
      header.merge!(DEFAULT_HEADER)
      begin
        response = RestClient::Request.execute(method: :delete, url: url,
                                               user: username,
                                               password: password,
                                               headers: header)
      rescue RestClient::ResourceNotFound => e
        raise CoachClient::NotFound, e.message
      rescue RestClient::Unauthorized => e
        raise CoachClient::Unauthorized, e.message
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end
  end
end


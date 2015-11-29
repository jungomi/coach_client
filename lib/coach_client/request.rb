module CoachClient
  module Request
    DEFAULT_HEADER = { accept: :json }

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
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end

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
      end
      CoachClient::Response.new(response.headers, response.body, response.code)
    end

    def self.delete(url, username: nil, password: nil, **header)
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


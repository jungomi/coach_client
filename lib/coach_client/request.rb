module CoachClient
  module Request
    DEFAULT_HEADER = { accept: :json }

    def self.get(url, username: nil, password: nil, **header)
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :get, url: url,
                                             user: username,
                                             password: password,
                                             headers: header)
      Response.new(response, response.code)
    end

    def self.put(url, username: nil, password: nil, payload:, **header)
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :put, url: url,
                                             user: username,
                                             password: password,
                                             payload: payload, headers: header)
      Response.new(response, response.code)
    end

    def self.post(url, username: nil, password: nil, payload:, **header)
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :post, url: url,
                                             user: username,
                                             password: password,
                                             payload: payload, headers: header)
      Response.new(response, response.code)
    end

    def self.delete(url, username: nil, password: nil, **header)
      response = RestClient::Request.execute(method: :delete, url: url,
                                             user: username,
                                             password: password,
                                             headers: header)
      Response.new(response, response.code)
    end
  end
end


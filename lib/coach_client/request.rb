module CoachClient
  module Request
    DEFAULT_HEADER = { accept: :json }

    def self.get(url, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :get, url: url,
                                             headers: header)
      Response.new(response, response.code)
    end

    def self.put(url, payload, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :put, url: url,
                                             payload: payload, headers: header)
      Response.new(response, response.code)
    end

    def self.post(url, payload, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :post, url: url,
                                             payload: payload, headers: header)
      Response.new(response, response.code)
    end

    def self.delete(url, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :delete, url: url,
                                             headers: header)
      Response.new(response, response.code)
    end
  end
end


module CoachClient

  class Request
    DEFAULT_HEADER = { accept: :json }

    def self.get(url, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :get, url: url,
                                             headers: header)
      self.new(response)
    end

    def self.put(url, payload, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :put, url: url,
                                             payload: payload, headers: header)
      self.new(response)
    end

    def self.post(url, payload, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :post, url: url,
                                             payload: payload, headers: header)
      self.new(response)
    end

    def self.delete(url, header={})
      header.merge!(DEFAULT_HEADER)
      response = RestClient::Request.execute(method: :delete, url: url,
                                             headers: header)
      self.new(response)
    end

    def initialize(body)
      @body = body
    end

    def to_h
      JSON.parse(@body, symbolize_names: true)
    end

    def to_s
      @body.to_s
    end
  end
end

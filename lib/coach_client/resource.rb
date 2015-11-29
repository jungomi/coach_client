module CoachClient
  class Resource
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def exist?(username: nil, password: nil)
      begin
        CoachClient::Request.get(url, username: username, password: password)
        true
      rescue CoachClient::NotFound
        false
      end
    end

    def to_h
      hash = {}
      instance_variables.each do |var|
        next if var.to_s == '@client'
        value = instance_variable_get(var)
        hash[var.to_s.delete('@').to_sym] =
          if value && value.respond_to?(:to_h) && !value.is_a?(Array)
            value.to_h
          else
            value
          end
      end
      hash
    end
  end
end

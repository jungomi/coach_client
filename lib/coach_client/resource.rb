module CoachClient
  # A resource of the CyberCoach service.
  class Resource
    # @return [CoachClient::Client]
    attr_accessor :client

    # Creates a new resource.
    #
    # @param [CoachClient::Client] client
    # @return [CoachClient::Resource]
    def initialize(client)
      @client = client
    end

    # Returns whether the resource exists on the CyberCoach service.
    #
    # @param [String] username
    # @param [String] password
    # @return [Boolean]
    def exist?(username: nil, password: nil)
      begin
        CoachClient::Request.get(url, username: username, password: password)
        true
      rescue CoachClient::NotFound
        false
      end
    end

    # Returns the hash representation of the resource.
    #
    # @return [Hash]
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

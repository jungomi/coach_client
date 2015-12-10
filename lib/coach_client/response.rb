module CoachClient
  # A response from RESTful request to the CyberCoach service.
  class Response
    attr_reader :code, :header

    # Creates a new response.
    #
    # @param [String] header the headers of the HTTP response
    # @param [String] body the body of the HTTP response
    # @param [Integer] code the HTTP response code
    # @return [CoachClient::Response]
    def initialize(header, body, code)
      @header = header
      @body = body
      @code = code
    end

    # Returns the body as Ruby Hash.
    #
    # @return [Hash]
    def to_h
      JSON.parse(@body, symbolize_names: true)
    end

    # Returns the body as String.
    #
    # @return [String]
    def to_s
      @body.to_s
    end
  end
end


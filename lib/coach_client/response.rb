module CoachClient
  class Response
    attr_reader :code

    def initialize(body, code)
      @body = body
      @code = code
    end

    def to_h
      JSON.parse(@body, symbolize_names: true)
    end

    def to_s
      @body.to_s
    end
  end
end


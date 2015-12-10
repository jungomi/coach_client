module CoachClient
  # A sport resource of the CyberCoach service.
  class Sport < CoachClient::Resource
    # @return [Integer]
    attr_reader :id

    # @return [Symbol]
    attr_reader :sport

    # @return [String]
    attr_reader :name, :description

    # Returns the relative path to the sport resource.
    #
    # @return [String] the relative path
    def self.path
      'sports/'
    end

    # Returns the total number of sports present on the CyberCoach service.
    #
    # @param [CoachClient::Client] client
    # @return [Integer] the total number of sports
    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    # Returns a list of sports from the CyberCoach service for which the given
    # block returns a true value.
    #
    # If no block is given, the whole list is returned.
    #
    # @param [CoachClient::Client] client
    # @yieldparam [CoachClient::Sport] sport the sport
    # @yieldreturn [Boolean] whether the sport should be added to the list
    # @return [Array<CoachClient::Sport>] the list of sports
    def self.list(client)
      sportlist  = []
      response = CoachClient::Request.get(client.url + path)
      response.to_h[:sports].each do |s|
        sport = self.new(client, s[:name])
        sportlist << sport if !block_given? || yield(sport)
      end
      sportlist
    end

    # Creates a new sport.
    #
    # @param [CoachClient::Client] client
    # @param [String, Symbol] sport
    # @return [CoachClient::Sport]
    def initialize(client, sport)
      super(client)
      @sport = sport.downcase.to_sym
    end

    # Updates the sport with the data from the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the sport does not exist
    # @return [CoachClient::Sport] the updated sport
    def update
      raise CoachClient::NotFound, 'Sport not found' unless exist?
      response = CoachClient::Request.get(url)
      response = response.to_h
      @id = response[:id]
      @name = response[:name]
      @description = response[:description]
      self
    end

    # Returns the URL of the sport.
    #
    # @return [String] the url of the sport
    def url
      @client.url + self.class.path + @sport.to_s
    end

    # Returns the string representation of the sport.
    #
    # @return [String]
    def to_s
      @sport.to_s
    end
  end
end


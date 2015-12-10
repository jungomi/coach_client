module CoachClient
  # A client to communicate with the CyberCoach service.
  #
  # @!attribute [r] url
  #   The URL of the CyberCoach service.
  #
  #   @return [String]
  class Client
    attr_reader :url

    # Creates a new client with the CyberCoach informations.
    #
    # @param [String] host the host address
    # @param [String] path the path to the resources
    # @return [CoachClient::Client]
    def initialize(host, path = '/')
      @url = host + path
    end

    # Returns whether the given credentials are valid.
    #
    # @param [String] username
    # @param [String] password
    # @return [Boolean]
    def authenticated?(username, password)
      begin
        CoachClient::Request.get("#{@url}authenticateduser/",
                                 username: username, password: password)
        true
      rescue CoachClient::Unauthorized
        false
      end
    end

    # Returns the sport from the CyberCoach service.
    #
    # @param [String, Symbol] sportname
    # @return [CoachClient::Sport]
    def get_sport(sportname)
      sport = CoachClient::Sport.new(self, sportname)
      sport.update
    end

    # Returns the user from the CyberCoach service.
    #
    # @param [String] username
    # @return [CoachClient::User]
    def get_user(username)
      user = CoachClient::User.new(self, username)
      user.update
    end

    # Returns the partnership from the CyberCoach service.
    #
    # @param [CoachClient::User, String] user1
    # @param [CoachClient::User, String] user2
    # @return [CoachClient::Partnership]
    def get_partnership(user1, user2)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      partnership.update
    end

    # Returns the subscription of a user from the CyberCoach service.
    #
    # @param [CoachClient::User, String] user
    # @param [CoachClient::Sport, String, Symbol] sport
    # @return [CoachClient::UserSubscription]
    def get_user_subscription(user, sport)
      subscription = CoachClient::UserSubscription.new(self, user, sport)
      subscription.update
    end

    # Returns the subscription of a partnership from the CyberCoach service.
    #
    # @param [CoachClient::User, String] user1
    # @param [CoachClient::User, String] user2
    # @param [CoachClient::Sport, String, Symbol] sport
    # @return [CoachClient::PartnershipSubscription]
    def get_partnership_subscription(user1, user2, sport)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      subscription = CoachClient::PartnershipSubscription.new(self, partnership, sport)
      subscription.update
    end
  end
end


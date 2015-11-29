module CoachClient
  class Client
    attr_reader :url

    def initialize(host, path='/')
      @url = host + path
    end

    def authenticated?(username, password)
      begin
        CoachClient::Request.get("#{@url}authenticateduser/",
                                 username: username, password: password)
        true
      rescue CoachClient::Unauthorized
        false
      end
    end

    def get_sport(sportname)
      sport = CoachClient::Sport.new(self, sportname)
      sport.update
    end

    def get_user(username)
      user = CoachClient::User.new(self, username)
      user.update
    end

    def get_partnership(user1, user2)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      partnership.update
    end

    def get_user_subscription(user, sport)
      subscription = CoachClient::UserSubscription.new(self, user, sport)
      subscription.update
    end

    def get_partnership_subscription(user1, user2, sport)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      subscription = CoachClient::PartnershipSubscription.new(self, partnership, sport)
      subscription.update
    end
  end
end


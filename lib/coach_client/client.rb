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
      rescue RestClient::Exception
        false
      end
    end

    def get_sport(sportname)
      sport = CoachClient::Sport.new(self, sportname)
      begin
        sport.update
      rescue RestClient::Exception
        raise CoachClient::NotFound, "Sport not found"
      end
    end

    def get_user(username)
      user = CoachClient::User.new(self, username)
      begin
        user.update
      rescue RestClient::Exception
        raise CoachClient::NotFound, "User not found"
      end
    end

    def get_partnership(user1, user2)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      begin
        partnership.update
      rescue RestClient::Exception
        raise CoachClient::NotFound, "Partnership not found"
      end
    end

    def get_user_subscription(user, sport)
      subscription = CoachClient::UserSubscription.new(self, user, sport)
      begin
        subscription.update
      rescue RestClient::Exception
        raise CoachClient::NotFound, "Subscription not found"
      end
    end

    def get_partnership_subscription(user1, user2, sport)
      partnership = CoachClient::Partnership.new(self, user1, user2)
      subscription = CoachClient::PartnershipSubscription.new(self, partnership, sport)
      begin
        subscription.update
      rescue RestClient::Exception
        raise CoachClient::NotFound, "Subscription not found"
      end
    end
  end
end


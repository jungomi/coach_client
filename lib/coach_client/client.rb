module CoachClient
  class Client
    attr_reader :url

    def initialize(host, path='/')
      @url = host + path
    end

    def authenticated?(username, password)
      begin
        CoachClient::AuthenticatedRequest.get("#{@url}authenticateduser/",
                                              username, password)
        true
      rescue RestClient::Exception
        false
      end
    end

    def get_sport(sportname)
      sport = CoachClient::sport.new(self, sportname)
      begin
        sport.update
      rescue RestClient::Exception
        raise "Sport not found"
      end
    end

    def get_user(username)
      user = CoachClient::User.new(self, username)
      begin
        user.update
      rescue RestClient::Exception
        raise "User not found"
      end
    end
  end
end


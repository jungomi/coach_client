module CoachClient
  class UserSubscription < Subscription
    attr_reader :id, :datesubscribed
    attr_accessor :user

    def self.path
      'users/'
    end

    def initialize(client, user, sport, info={})
      super(client, sport, info)
      @user = if user.is_a?(CoachClient::User)
                user
              else
                CoachClient::User.new(client, user)
              end
    end

    def update
      super(@user)
    end

    def save
      super(@user)
    end

    def delete
      super(@user)
    end

    def url
      "#{@user.url}/#{@sport}"
    end

    def to_s
      "#{@user.username}/#{@sport}"
    end
  end
end


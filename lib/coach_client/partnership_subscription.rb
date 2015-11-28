module CoachClient
  class PartnershipSubscription < Subscription
    attr_reader :id, :datesubscribed
    attr_accessor :partnership

    def self.path
      'partnerships/'
    end

    def initialize(client, partnership, sport, publicvisible: nil)
      super(client, sport, publicvisible: publicvisible)
      @partnership = if partnership.is_a?(CoachClient::Partnership)
                       partnership
                     else
                       uri = "partnerships/#{partnership}/"
                       users = CoachClient::Partnership.extractUsersFromURI(uri)
                       CoachClient::Partnership.new(client, *users)
                     end
    end

    def update
      if @client.authenticated?(@partnership.user1.username,
                                @partnership.user1.password)
        super(@partnership.user1)
      else
        super(@partnership.user2)
      end
    end

    def save
      if @client.authenticated?(@partnership.user1.username,
                                @partnership.user1.password)
        super(@partnership.user1)
      else
        super(@partnership.user2)
      end
    end

    def delete
      if @client.authenticated?(@partnership.user1.username,
                                @partnership.user1.password)
        super(@partnership.user1)
      else
        super(@partnership.user2)
      end
    end

    def url
      "#{@partnership.url}/#{@sport}"
    end

    def to_s
      "#{@partnership}/#{@sport}"
    end
  end
end


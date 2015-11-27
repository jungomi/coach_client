module CoachClient
  class PartnershipSubscription < Subscription
    attr_reader :id, :datesubscribed
    attr_accessor :partnership

    def self.path
      'partnerships/'
    end

    def initialize(client, partnership, sport, info={})
      super(client, sport, info)
      @partnership = partnership
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


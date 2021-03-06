module CoachClient
  # A partnership subscription resource of the CyberCoach service.
  class PartnershipSubscription < CoachClient::Subscription
    # @return [Integer]
    attr_reader :id, :datesubscribed

    # @return [CoachClient::Partnership]
    attr_accessor :partnership

    # Returns the relative path to the partnership subscription resource.
    #
    # @return [String] the relative path
    def self.path
      'partnerships/'
    end

    # Creates a new partnership subscription.
    #
    # @param [CoachClient::Client] client
    # @param [String, CoachClient::Partnership] partnership
    # @param [String, Symbol, CoachClient::Sport] sport
    # @param [Integer] publicvisible
    # @return [CoachClient::PartnershipSubscription]
    def initialize(client, partnership, sport, publicvisible: nil)
      super(client, sport, publicvisible: publicvisible)
      @partnership = if partnership.is_a?(CoachClient::Partnership)
                       partnership
                     else
                       uri = "partnerships/#{partnership}/"
                       users = CoachClient::Partnership.extract_users_from_uri(uri)
                       CoachClient::Partnership.new(client, *users)
                     end
    end

    # Updates the partnership subscription with the data from the CyberCoach
    # service.
    #
    # @param [Integer] size the number of entries
    # @param [Integer] start the start of entries list
    # @param [Boolean] all whether all entries are retrieved
    # @raise [CoachClient::NotFound] if the partnership subscription does not
    #   exist
    # @return [CoachClient::PartnershipSubscription] the updated partnership
    #   subscription
    def update(size: 20, start: 0, all: false)
      begin
        super(@partnership.user1, size: size, start: start, all: all)
      rescue CoachClient::Exception
        super(@partnership.user2, size: size, start: start, all: all)
      end
    end

    # Saves the partnership subscription to the CyberCoach service.
    #
    # The partnership subscription is created if it does not exist on the
    # CyberCoach service, otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the partnership subscription could not
    #   be saved
    # @return [CoachClient::PartnershipSubscription] the saved partnership
    #   subscription
    def save
      begin
        super(@partnership.user1)
      rescue CoachClient::Exception
        super(@partnership.user2)
      end
    end

    # Deletes the partnership subscription on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the partnership subscription does not
    #   exist
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [true]
    def delete
      begin
        super(@partnership.user1)
      rescue CoachClient::Exception
        super(@partnership.user2)
      end
    end

    # Returns the URL of the partnership subscription.
    #
    # @return [String] the url of the partnership subscription
    def url
      "#{@partnership.url}/#{@sport}"
    end

    # Returns the string representation of the partnership subscription.
    #
    # @return [String]
    def to_s
      "#{@partnership}/#{@sport}"
    end
  end
end

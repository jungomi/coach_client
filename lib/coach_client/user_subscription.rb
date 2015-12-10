module CoachClient
  # A user subscription resource of the CyberCoach service.
  class UserSubscription < CoachClient::Subscription
    # @return [Integer]
    attr_reader :id, :datesubscribed

    # @return [CoachClient::User]
    attr_accessor :user

    # Returns the relative path to the user subscription resource.
    #
    # @return [String] the relative path
    def self.path
      'users/'
    end

    # Creates a new user subscription.
    #
    # @param [CoachClient::Client] client
    # @param [String, CoachClient::User] user
    # @param [String, Symbol, CoachClient::Sport] sport
    # @param [Integer] publicvisible
    # @return [CoachClient::UserSubscription]
    def initialize(client, user, sport, publicvisible: nil)
      super(client, sport, publicvisible: publicvisible)
      @user = if user.is_a?(CoachClient::User)
                user
              else
                CoachClient::User.new(client, user)
              end
    end

    # Updates the user subscription with the data from the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the user subscription does not exist
    # @return [CoachClient::UserSubscription] the updated user subscription
    def update
      super(@user)
    end

    # Saves the user subscription to the CyberCoach service.
    #
    # The user subscription is created if it does not exist on the CyberCoach
    # service, otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the user subscription could not be saved
    # @return [CoachClient::UserSubscription] the saved user subscription
    def save
      super(@user)
    end

    # Deletes the user subscription on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the user subscription does not exist
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [true]
    def delete
      super(@user)
    end

    # Returns the URL of the user subscription.
    #
    # @return [String] the url of the user subscription
    def url
      "#{@user.url}/#{@sport}"
    end

    # Returns the string representation of the user subscription.
    #
    # @return [String]
    def to_s
      "#{@user.username}/#{@sport}"
    end
  end
end


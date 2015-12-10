module CoachClient
  # A subscription resource of the CyberCoach service.
  #
  # @note Use the subclass {CoachClient::UserSubscription} or
  #   {CoachClient::PartnershipSubscription} for a user or partnership
  #   subscription respectively.
  class Subscription < CoachClient::Resource
    # @return [Integer]
    attr_reader :id, :datesubscribed

    # @return [Array<CoachClient::Entry>]
    attr_reader :entries

    # @return [CoachClient::Sport]
    attr_accessor :sport

    # @return [Integer]
    attr_accessor :publicvisible

    # Creates a new subscription.
    #
    # @param [CoachClient::Client] client
    # @param [String, Symbol, CoachClient::Sport] sport
    # @param [Integer] publicvisible
    # @return [CoachClient::Subscription]
    def initialize(client, sport, publicvisible: nil)
      super(client)
      @sport = if sport.is_a?(CoachClient::Sport)
                 sport
               else
                 CoachClient::Sport.new(client, sport)
               end
      @publicvisible = publicvisible
    end

    # Updates the subscription with the data from the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the subscription does not exist
    # @param [CoachClient::User] user
    # @return [CoachClient::Subscription] the updated subscription
    def update(user)
      response = CoachClient::Request.get(url, username: user.username,
                                          password: user.password)
      response = response.to_h
      @id = response[:id]
      @datesubscribed = response[:datesubscribed]
      @publicvisible = response[:publicvisible]
      @entries = []
      unless response[:entries].nil?
        response[:entries].each do |e|
          tag = "entry#{@sport}"
          id = CoachClient::Entry.extract_id_from_uri(e[tag.to_sym][:uri])
          @entries << CoachClient::Entry.new(client, self, id: id)
        end
      end
      self
    end

    # Saves the subscription to the CyberCoach service.
    #
    # The subscription is created if it does not exist on the CyberCoach service,
    # otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the subscription could not be saved
    # @param [CoachClient::User] user
    # @return [CoachClient::Subscription] the saved subscription
    def save(user)
      vals = to_h
      vals.delete(:user)
      vals.delete(:partnership)
      vals.delete(:sport)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      payload = Gyoku.xml(subscription: vals)
      response = CoachClient::Request.put(url, username: user.username,
                                          password: user.password,
                                          payload: payload,
                                          content_type: :xml)
      unless response.code == 200 || response.code == 201
        fail CoachClient::NotSaved.new(self), 'Could not save subscription'
      end
      self
    end

    # Deletes the subscription on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the subscription does not exist
    # @raise [CoachClient::Unauthorized] if not authorized
    # @param [CoachClient::User] user
    # @return [true]
    def delete(user)
      CoachClient::Request.delete(url, username: user.username,
                                  password: user.password)
      true
    end
  end
end


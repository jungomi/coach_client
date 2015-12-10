module CoachClient
  # A entry resource of the CyberCoach serivce.
  class Entry < CoachClient::Resource
    # @return [Integer]
    attr_reader :id, :datecreated, :datemodified

    # @return [Integer]
    attr_accessor :publicvisible, :entryduration

    # @return [Date]
    attr_accessor :entrydate

    # @return [CoachClient::Subscription]
    attr_accessor :subscription

    # @return [String]
    attr_accessor :comment, :entrylocation

    # Extracts the entry id from the URI
    #
    # @param [String] uri
    # @return [String] the entry id
    def self.extract_id_from_uri(uri)
      match = uri.match(/\/(\d+)\/\z/)
      match.captures.first
    end

    # Creates a new entry.
    #
    # @param [CoachClient::Client] client
    # @param [CoachClient::Subscription] subscription
    # @param [Hash] info
    # @option info [Integer] :id
    # @option info [Integer] :publicvisible
    # @option info [String] :comment
    # @option info [Date] :entrydate
    # @option info [Integer] :entryduration
    # @option info [String] :entrylocation
    # @return [CoachClient::Entry]
    def initialize(client, subscription, info = {})
      super(client)
      @subscription = subscription
      @id = info[:id]
      @publicvisible = info[:publicvisible]
      @comment = info[:comment]
      @entrydate = info[:entrydate]
      @entryduration = info[:entryduration]
      @entrylocation = info[:entrylocation]
    end

    # Updates the entry with the data from the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the entry does not exist
    # @return [CoachClient::User] the updated user
    def update
      raise CoachClient::NotFound, 'Entry not found' unless exist?
      response = if @client.authenticated?(user.username, user.password)
                   CoachClient::Request.get(url, username: user.username,
                                            password: user.password)
                 else
                   CoachClient::Request.get(url)
                 end
      tag = "entry#{@subscription.sport}"
      response = response.to_h[tag.to_sym]
      @datecreated = response[:datecreated]
      @datemodified = response[:datemodified]
      @publicvisible = response[:publicvisible]
      @comment = response[:comment]
      @entrydate = response[:entrydate]
      @entryduration = response[:entryduration]
      @entrylocation = response[:entrylocation]
      self
    end

    # Creates the entry on the CyberCoach service.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the entry could not be saved
    # @return [CoachClient::Entry] the created entry
    def create
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), 'Unauthorized'
      end
      begin
        response = CoachClient::Request.post(@subscription.url,
                                             username: user.username,
                                             password: user.password,
                                             payload: payload,
                                             content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), 'Could not create entry'
      end
      @id = self.class.extract_id_from_uri(response.header[:location])
      self
    end

    # Saves the entry to the CyberCoach service.
    #
    # The entry is created if it does not exist on the CyberCoach service,
    # otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the entry could not be saved
    # @return [CoachClient::Entry] the created entry
    def save
      return create unless @id
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), 'Unauthorized'
      end
      begin
        response = CoachClient::Request.put(url, username: user.username,
                                            password: user.password,
                                            payload: payload,
                                            content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), 'Could not save entry'
      end
      self
    end

    # Returns the user that is used for the authentication.
    #
    # @return [CoachClient::User]
    def user
      if @subscription.is_a?(CoachClient::PartnershipSubscription)
        partnership = @subscription.partnership
        if @client.authenticated?(partnership.user1.username, partnership.user1.password)
          partnership.user1
        else
          partnership.user2
        end
      else
        @subscription.user
      end
    end

    # Deletes the entry on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the entry does not exist
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [true]
    def delete
      raise CoachClient::NotFound.new(self), 'Entry not found' unless exist?
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), 'Unauthorized'
      end
      CoachClient::Request.delete(url, username: user.username,
                                  password: user.password)
      true
    end

    # Returns whether the resource exists on the CyberCoach service.
    #
    # @param [String] username
    # @param [String] password
    # @return [Boolean]
    def exist?(username: nil, password: nil)
      return false unless @id
      if @client.authenticated?(user.username, user.password)
        super(username: user.username, password: user.password)
      else
        super
      end
    end

    # Returns the URL of the entry.
    #
    # @return [String] the url of the entry
    def url
      "#{@subscription.url}/#{@id}"
    end

    # Returns the string representation of the entry.
    #
    # @return [String]
    def to_s
      @id.to_s
    end

    private

    def payload
      vals = self.to_h
      vals.delete(:subscription)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      tag = "entry#{@subscription.sport}"
      Gyoku.xml(tag.to_sym => vals)
    end
  end
end


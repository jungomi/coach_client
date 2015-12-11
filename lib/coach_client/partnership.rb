module CoachClient
  # A partnership resource of the CyberCoach service.
  class Partnership < CoachClient::Resource
    # The size of the requests for the {.list} with all = true
    LIST_ALL_SIZE = 1000

    # @return [Integer]
    attr_reader :id, :datecreated

    # @return [Boolean]
    attr_reader :user1_confirmed, :user2_confirmed

    # @return [Array<CoachClient::Subscription>]
    attr_reader :subscriptions

    # @return [CoachClient::User]
    attr_accessor :user1, :user2

    # @return [Integer]
    attr_accessor :publicvisible

    # Returns the relative path to the partnership resource.
    #
    # @return [String] the relative path
    def self.path
      'partnerships/'
    end

    # Extracts the usernames from the partnership URI
    #
    # @param [String] uri
    # @return [Array<String>] the usernames
    def self.extract_users_from_uri(uri)
      match = uri.match(/partnerships\/(\w+);(\w+)\//)
      match.captures
    end

    # Returns the total number of partnerships present on the CyberCoach service.
    #
    # @param [CoachClient::Client] client
    # @return [Integer] the total number of partnerships
    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    # Returns a list of partnerships from the CyberCoach service for which the
    # given block returns a true value.
    #
    # If no block is given, the whole list is returned.
    #
    # @param [CoachClient::Client] client
    # @param [Integer] size
    # @param [Integer] start
    # @param [Boolean] all
    # @yieldparam [CoachClient::Partnership] partnership the partnership
    # @yieldreturn [Boolean] whether the partnership should be added to the list
    # @return [Array<CoachClient::Partnership>] the list of partnerships
    def self.list(client, size: 20, start: 0, all: false)
      list = []
      if all
        total = self.total(client)
        start = 0
        size = LIST_ALL_SIZE
      end
      loop do
        response = CoachClient::Request.get(client.url + path,
                                            params: { start: start, size: size })
        response.to_h[:partnerships].each do |p|
          user1, user2 = extract_users_from_uri(p[:uri])
          partnership = new(client, user1, user2)
          list << partnership if !block_given? || yield(partnership)
        end
        break unless all
        start += size
        break if start >= total
      end
      list
    end

    # Creates a new partnership.
    #
    # @param [CoachClient::Client] client
    # @param [String, CoachClient::User] user1
    # @param [String, CoachClient::User] user2
    # @param [Integer] publicvisible
    # @return [CoachClient::Partnership]
    def initialize(client, user1, user2, publicvisible: nil)
      super(client)
      @user1 = if user1.is_a?(CoachClient::User)
                 user1
               else
                 CoachClient::User.new(client, user1)
               end
      @user2 = if user2.is_a?(CoachClient::User)
                 user2
               else
                 CoachClient::User.new(client, user2)
               end
      @publicvisible = publicvisible
    end

    # Updates the partnership with the data from the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the partnership does not exist
    # @return [CoachClient::Partnership] the updated partnership
    def update
      response = begin
                   CoachClient::Request.get(url, username: @user1.username,
                                            password: @user1.password)
                 rescue CoachClient::Exception
                   CoachClient::Request.get(url, username: @user2.username,
                                            password: @user2.password)
                 end
      response = response.to_h
      @id = response[:id]
      @datecreated = response[:datecreated]
      @publicvisible = response[:publicvisible]
      set_user_confirmed(response)
      @subscriptions = []
      unless response[:subscriptions].nil?
        response[:subscriptions].each do |s|
          sport = s[:uri].match(/\/(\w+)\/\z/).captures.first
          @subscriptions << CoachClient::PartnershipSubscription.new(client, self,
                                                                     sport)
        end
      end
      self
    end

    # Saves the partnership to the CyberCoach service.
    #
    # The partnership is created if it does not exist on the CyberCoach service,
    # otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the partnership could not be saved
    # @return [CoachClient::Partnership] the saved partnership
    def save
      unless operational?
        propose unless @user1_confirmed
        return confirm
      end
      response = begin
                   CoachClient::Request.put(url, username: @user1.username,
                                            password: @user1.password,
                                            payload: payload,
                                            content_type: :xml)
                 rescue CoachClient::Exception
                   CoachClient::Request.put(url, username: @user2.username,
                                            password: @user2.password,
                                            payload: payload,
                                            content_type: :xml)
                 end
      unless response.code == 200 || response.code == 201
        fail CoachClient::NotSaved.new(self), 'Could not save partnership'
      end
      self
    end

    # Proposes the partnership on the CyberCoach service.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotProposed] if the partnership could not be proposed
    # @return [CoachClient::Partnership] the proposed partnership
    def propose
      response = CoachClient::Request.put(url, username: @user1.username,
                                          password: @user1.password,
                                          payload: payload,
                                          content_type: :xml)
      unless response.code == 200 || response.code == 201
        fail CoachClient::NotProposed.new(self), 'Could not propose partnership'
      end
      set_user_confirmed(response.to_h)
      self
    end

    # Confirms the partnership on the CyberCoach service.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotConfirmed] if the partnership could not be proposed
    # @return [CoachClient::Partnership] the confirmed partnership
    def confirm
      response = CoachClient::Request.put(url, username: @user2.username,
                                          password: @user2.password,
                                          payload: payload,
                                          content_type: :xml)
      unless response.code == 200 || response.code == 201
        fail CoachClient::NotConfirmed.new(self), 'Could not confirm partnership'
      end
      set_user_confirmed(response.to_h)
      self
    end

    # Cancels the partnership on the CyberCoach service.
    #
    # This sets the confirmation status of user1 to false.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [CoachClient::Partnership] the invalidated partnership
    def cancel
      response = CoachClient::Request.delete(url, username: @user1.username,
                                             password: @user1.password)
      set_user_confirmed(response.to_h)
      self
    end

    # Invalidates the partnership on the CyberCoach service.
    #
    # This sets the confirmation status of user2 to false.
    #
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [CoachClient::Partnership] the invalidated partnership
    def invalidate
      response = CoachClient::Request.delete(url, username: @user2.username,
                                             password: @user2.password)
      set_user_confirmed(response.to_h)
      self
    end

    # Deletes the partnership on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the partnership does not exist
    # @raise [CoachClient::Unauthorized] if not authorized
    # @return [true]
    def delete
      fail CoachClient::NotFound unless exist?
      invalidate if @user2_confirmed
      if @user1_confirmed
        response = CoachClient::Request.delete(url, username: @user1.username,
                                              password: @user1.password)
        set_user_confirmed(response.to_h)
      end
      true
    end

    # Returns whether the partnership is operational.
    #
    # @return [Boolean]
    def operational?
      @user1_confirmed && @user2_confirmed
    end

    # Returns the URL of the partnership.
    #
    # @return [String] the url of the partnership
    def url
      "#{@client.url}#{self.class.path}#{@user1.username};#{@user2.username}"
    end

    # Returns the string representation of the user.
    #
    # @return [String]
    def to_s
      "#{@user1.username};#{@user2.username}"
    end

    private

    def payload
      vals = to_h
      vals.delete(:user1)
      vals.delete(:user2)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      Gyoku.xml(partnership: vals)
    end

    def set_user_confirmed(response)
      if response[:user1][:username] == @user1.username
        @user1_confirmed = response[:userconfirmed1]
        @user2_confirmed = response[:userconfirmed2]
      else
        @user1_confirmed = response[:userconfirmed2]
        @user2_confirmed = response[:userconfirmed1]
      end
    end
  end
end

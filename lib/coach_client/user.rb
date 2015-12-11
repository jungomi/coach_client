module CoachClient
  # A user resource of the CyberCoach service.
  class User < CoachClient::Resource
    # @return [String]
    attr_reader :username

    # @return [Integer]
    attr_reader :datecreated

    # @return [Array<CoachClient::Partnership>]
    attr_reader :partnerships

    # @return [Array<CoachClient::UserSubscription>]
    attr_reader :subscriptions

    # @return [String]
    attr_accessor :password, :realname, :email, :newpassword

    # @return [Integer]
    attr_accessor :publicvisible

    # Returns the relative path to the user resource.
    #
    # @return [String] the relative path
    def self.path
      'users/'
    end

    # Returns the total number of users present on the CyberCoach service.
    #
    # @param [CoachClient::Client] client
    # @return [Integer] the total number of users
    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    # Returns a list of users from the CyberCoach service for which the given
    # block returns a true value.
    #
    # If no block is given, the whole list is returned.
    #
    # @param [CoachClient::Client] client
    # @param [Integer] size
    # @param [Integer] start
    # @param [Boolean] all
    # @yieldparam [CoachClient::User] user the user
    # @yieldreturn [Boolean] whether the user should be added to the list
    # @return [Array<CoachClient::User>] the list of users
    def self.list(client, size: 20, start: 0, all: false)
      userlist = []
      if all
        total = self.total(client)
        start = 0
        size = client.max_size
      end
      loop do
        response = CoachClient::Request.get(client.url + path,
                                            params: { start: start, size: size })
        response.to_h[:users].each do |u|
          user = new(client, u[:username])
          userlist << user if !block_given? || yield(user)
        end
        break unless all
        start += size
        break if start >= total
      end
      userlist
    end

    # Creates a new user.
    #
    # @param [CoachClient::Client] client
    # @param [String] username
    # @param [Hash] info additional user informations
    # @option info [String] :password
    # @option info [String] :realname
    # @option info [String] :email
    # @option info [Integer] :publicvisible
    # @return [CoachClient::User]
    def initialize(client, username, info = {})
      super(client)
      @username = username
      @password = info[:password]
      @realname = info[:realname]
      @email = info[:email]
      @publicvisible = info[:publicvisible]
    end

    # Updates the user with the data from the CyberCoach service.
    #
    # @param [Integer] size the number of partnerships
    # @param [Integer] start the start of partnerships list
    # @param [Boolean] all whether all partnerships are retrieved
    # @raise [CoachClient::NotFound] if the user does not exist
    # @return [CoachClient::User] the updated user
    def update(size: 20, start: 0, all: false)
      response = {}
      if all
        start = 0
        size = @client.max_size
      end
      @partnerships = []
      loop do
        response = CoachClient::Request.get(url, username: @username,
                                            password: @password,
                                            params: { start: start, size: size })
        response = response.to_h
        break if response[:partnerships].nil?
        response[:partnerships].each do |p|
          users = CoachClient::Partnership.extract_users_from_uri(p[:uri])
          users.reject! { |username| username == @username }
          @partnerships << CoachClient::Partnership.new(client, self, users.first)
        end
        break unless all && has_next(response[:links])
        start += size
      end
      @realname = response[:realname]
      @email = response[:email]
      @publicvisible = response[:publicvisible]
      @datecreated = response[:datecreated]
      @subscriptions = []
      unless response[:subscriptions].nil?
        response[:subscriptions].each do |s|
          sport = s[:uri].match(/\/(\w+)\/\z/).captures.first
          @subscriptions << CoachClient::UserSubscription.new(client, self, sport)
        end
      end
      self
    end

    # Saves the user to the CyberCoach service.
    #
    # The user is created if it does not exist on the CyberCoach service,
    # otherwise it tries to overwrite it.
    #
    # @raise [CoachClient::Unauthorized] if the user is not authorized
    # @raise [CoachClient::IncompleteInformation] if not all needed information
    #   is given
    # @raise [CoachClient::NotSaved] if the user could not be saved
    # @return [CoachClient::User] the saved user
    def save
      vals = to_h
      vals.delete(:username)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      vals[:password] = vals.delete(:newpassword) if vals[:newpassword]
      payload = Gyoku.xml(user: vals)
      response = CoachClient::Request.put(url, username: @username,
                                          password: @password,
                                          payload: payload,
                                          content_type: :xml)
      unless response.code == 200 || response.code == 201
        fail CoachClient::NotSaved.new(self), 'Could not save user'
      end
      @password = vals[:password]
      @newpassword = nil
      self
    end

    # Deletes the user on the CyberCoach service.
    #
    # @raise [CoachClient::NotFound] if the user does not exist
    # @raise [CoachClient::Unauthorized] if the user is not authorized
    # @return [true]
    def delete
      fail CoachClient::NotFound.new(self), 'User not found' unless exist?
      CoachClient::Request.delete(url, username: @username, password: @password)
      true
    end

    # Returns whether the user is authenticated.
    #
    # @return [Boolean]
    def authenticated?
      false if @password.nil?
      @client.authenticated?(@username, @password)
    end

    # Returns the URL of the user.
    #
    # @return [String] the url of the user
    def url
      @client.url + self.class.path + @username
    end

    # Returns the string representation of the user.
    #
    # @return [String]
    def to_s
      @username.to_s
    end
  end
end

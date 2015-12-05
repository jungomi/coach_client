module CoachClient
  class User < Resource
    LIST_ALL_SIZE = 1000

    attr_reader :username, :datecreated, :partnerships, :subscriptions
    attr_accessor :password, :realname, :email, :publicvisible, :newpassword

    def self.path
      'users/'
    end

    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    def self.list(client, size: 20, start: 0, all: false)
      userlist  = []
      if all
        total = self.total(client)
        start = 0
        size = LIST_ALL_SIZE
      end
      loop do
        response = CoachClient::Request.get(client.url + path,
                                            params: { start: start, size: size })
        response.to_h[:users].each do |u|
          user = self.new(client, u[:username])
          userlist << user if !block_given? || yield(user)
        end
        break unless all
        start += size
        break if start >= total
      end
      userlist
    end

    def initialize(client, username, info = {})
      super(client)
      @username = username
      @password = info[:password]
      @realname = info[:realname]
      @email = info[:email]
      @publicvisible = info[:publicvisible]
    end

    def update
      raise CoachClient::NotFound, 'User not found' unless exist?
      response = if @client.authenticated?(@username, @password)
                   CoachClient::Request.get(url, username: @username,
                                            password: @password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @realname = response[:realname]
      @email = response[:email]
      @publicvisible = response[:publicvisible]
      @datecreated = response[:datecreated]
      @partnerships = []
      unless response[:partnerships].nil?
        response[:partnerships].each do |p|
          users = CoachClient::Partnership.extract_users_from_uri(p[:uri])
          users.reject! { |username| username == @username }
          @partnerships << CoachClient::Partnership.new(client, self, users.first)
        end
      end
      @subscriptions = []
      unless response[:subscriptions].nil?
        response[:subscriptions].each do |s|
          sport = s[:uri].match(/\/(\w+)\/\z/).captures.first
          @subscriptions << CoachClient::UserSubscription.new(client, self, sport)
        end
      end
      self
    end

    def save
      vals = self.to_h
      vals.delete(:username)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      vals[:password] = vals.delete(:newpassword) if vals[:newpassword]
      payload = Gyoku.xml(user: vals)
      response = if exist?
                   unless @client.authenticated?(@username, @password)
                     raise CoachClient::Unauthorized.new(self), 'Unauthorized'
                   end
                   CoachClient::Request.put(url, username: @username,
                                            password: @password,
                                            payload: payload,
                                            content_type: :xml)
                 else
                   begin
                     CoachClient::Request.put(url, payload: payload,
                                              content_type: :xml)
                   rescue RestClient::Conflict
                     raise CoachClient::IncompleteInformation.new(self),
                       'Incomplete user information'
                   end
                 end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), 'Could not save user'
      end
      @password = vals[:password]
      @newpassword = nil
      self
    end

    def delete
      unless @client.authenticated?(@username, @password)
        raise CoachClient::Unauthorized.new(self), 'Unauthorized'
      end
      CoachClient::Request.delete(url, username: @username, password: @password)
      true
    end

    def url
      @client.url + self.class.path + @username
    end

    def to_s
      @username.to_s
    end
  end
end


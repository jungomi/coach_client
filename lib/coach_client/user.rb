module CoachClient
  class User
    attr_reader :username
    attr_accessor :client, :password, :realname, :email, :publicvisible,
      :newpassword

    def self.path
      'users/'
    end

    def self.list(client, size=20, start=0)
      response = CoachClient::Request.get(client.url + path,
                                          params: { start: start, size: size })
      userlist  = []
      response.to_h[:users].each do |u|
        user = self.new(client, u[:username])
        userlist << user if !block_given? || yield(user)
      end
      userlist
    end

    def initialize(client, username, info={})
      @client = client
      @username = username
      @password = info[:password]
      @realname = info[:realname]
      @email = info[:email]
      @publicvisible = info[:publicvisible] || 2
    end

    def update
      raise "User not found" unless exist?
      response = if @client.authenticated?(@username, @password)
                   CoachClient::AuthenticatedRequest.get(url, @username,
                                                         @password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @realname = response[:realname]
      @email = response[:email]
      @publicvisible = response[:publicvisible]
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
                     raise "Unauthorized"
                   end
                   CoachClient::AuthenticatedRequest.put(url, @username,
                                                         @password, payload,
                                                         content_type: :xml)
                 else
                   begin
                     CoachClient::Request.put(url, payload, content_type: :xml)
                   rescue RestClient::Conflict
                     raise "Incomplete user information"
                   end
                 end
      unless response.code == 200 || response.code == 201
        raise "Could not save user"
      end
      @password = vals[:password]
      @newpassword = nil
      self
    end

    def delete
      raise "Unauthorized" unless @client.authenticated?(@username, @password)
      CoachClient::AuthenticatedRequest.delete(url, @username,
                                               @password)
      true
    end

    def exist?
      begin
        CoachClient::Request.get(url)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

    def url
      @client.url + self.class.path + @username
    end

    def to_h
      hash = {}
      instance_variables.each do |var|
        next if var.to_s == '@client'
        hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
      end
      hash
    end

    def to_s
      username.to_s
    end
  end
end


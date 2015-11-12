module CoachClient
  class User
    attr_reader :username
    attr_accessor :client, :password, :realname, :email, :publicvisible,
      :newpassword

    def initialize(client, username)
      @client = client
      @username = username
    end

    def update
      url = @client.url + path
      response = if @client.authenticated?(@username, @password)
                   AuthenticatedRequest.get(url, @username, @password)
                 else
                   Request.get(url)
                 end
      response = response.to_h
      @realname = response[:realname]
      @email = response[:email]
      @publicvisible = response[:publicvisible]
      self
    end

    def save
      raise "Unauthorized" unless @client.authenticated?(@username, @password)
      vals = self.to_h
      vals.delete(:username)
      vals.delete_if { |_k, v| v.nil? }
      vals[:password] = vals.delete(:newpassword) if vals[:newpassword]
      payload = Gyoku.xml(user: vals)
      response = AuthenticatedRequest.put(@client.url + path, @username,
                                          @password, payload,
                                          { content_type: :xml })
      unless response.code == 200 || response.code == 201
        raise "Could not save user"
      end
      @password = vals[:password]
      @newpassword = nil
      self
    end

    def path
      "users/#{@username}"
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


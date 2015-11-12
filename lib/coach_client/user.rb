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
      puts response
      @realname = response[:realname]
      @email = response[:email]
      @publicvisible = response[:publicvisible]
      self
    end

    def path
      "users/#{@username}"
    end

    def to_s
      username.to_s
    end
  end
end


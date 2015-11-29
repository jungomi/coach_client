module CoachClient
  class Partnership < Resource
    LIST_ALL_SIZE = 1000

    attr_reader :id, :datecreated, :user1_confirmed, :user2_confirmed,
      :subscriptions
    attr_accessor :user1, :user2, :publicvisible

    def self.path
      'partnerships/'
    end

    def self.extract_users_from_uri(uri)
      match = uri.match(/partnerships\/(\w+);(\w+)\//)
      match.captures
    end

    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    def self.list(client, size: 20, start: 0, all: false)
      list  = []
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
          partnership = self.new(client, user1, user2)
          list << partnership if !block_given? || yield(partnership)
        end
        break unless all
        start += size
        break if start >= total
      end
      list
    end

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

    def update
      raise CoachClient::NotFound.new(self), 'Partnership not found' unless exist?
      response = if @client.authenticated?(@user1.username, @user1.password)
                   CoachClient::Request.get(url, username: @user1.username,
                                            password: @user1.password)
                 elsif @client.authenticated?(@user2.username, @user2.password)
                   CoachClient::Request.get(url, username:@user2.username,
                                            password: @user2.password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @id = response[:id]
      @datecreated = response[:datecreated]
      @publicvisible = response[:publicvisible]
      @user1_confirmed = response[:userconfirmed1]
      @user2_confirmed = response[:userconfirmed2]
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

    def save
      unless operational?
        propose unless @user1_confirmed
        return confirm
      end
      user1 = @client.authenticated?(@user1.username, @user1.password)
      user2 = @client.authenticated?(@user2.username, @user2.password) unless user1
      unless user1 || user2
        raise CoachClient::Unauthorized.new(@user2), 'Unauthorized'
      end
      begin
        response = if user1
                     CoachClient::Request.put(url, username: @user1.username,
                                              password: @user1.password,
                                              payload: payload,
                                              content_type: :xml)
                   else
                     CoachClient::Request.put(url, username: @user2.username,
                                              password: @user2.password,
                                              payload: payload,
                                              content_type: :xml)
                   end
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), 'Could not save partnership'
      end
      self
    end

    def propose
      unless @client.authenticated?(@user1.username, @user1.password)
        raise CoachClient::Unauthorized.new(@user1), 'Unauthorized'
      end
      begin
        response = CoachClient::Request.put(url, username: @user1.username,
                                            password: @user1.password,
                                            payload: payload,
                                            content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotProposed.new(self), 'Could not propose partnership'
      end
      @user1_confirmed = true
      self
    end

    def confirm
      unless @client.authenticated?(@user2.username, @user2.password)
        raise CoachClient::Unauthorized.new(@user2), 'Unauthorized'
      end
      begin
        response = CoachClient::Request.put(url, username: @user2.username,
                                            password: @user2.password,
                                            payload: payload,
                                            content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotConfirmed.new(self), 'Could not confirm partnership'
      end
      @user2_confirmed = true
      self
    end

    def invalidate
      unless @client.authenticated?(@user2.username, @user2.password)
          raise CoachClient::Unauthorized.new(@user2), 'Unauthorized'
      end
      CoachClient::Request.delete(url, username: @user2.username,
                                  password: @user2.password)
      @user2_confirmed = false
      true
    end

    def delete
      invalidate if operational?
      unless @client.authenticated?(@user1.username, @user1.password)
        raise CoachClient::Unauthorized.new(@user1), 'Unauthorized'
      end
      CoachClient::Request.delete(url, username: @user1.username,
                                  password: @user1.password)
      @user1_confirmed = false
      true
    end

    def operational?
      @user1_confirmed && @user2_confirmed
    end

    def url
      "#{@client.url}#{self.class.path}#{@user1.username};#{@user2.username}"
    end

    def to_s
      "#{@user1.username};#{@user2.username}"
    end

    private

    def payload
      vals = self.to_h
      vals.delete(:user1)
      vals.delete(:user2)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      Gyoku.xml(partnership: vals)
    end
  end
end

module CoachClient
  class Partnership
    LIST_ALL_SIZE = 1000

    attr_reader :id, :datecreated, :user1_confirmed, :user2_confirmed
    attr_accessor :client, :user1, :user2, :publicvisible

    def self.path
      'partnerships/'
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
          user1, user2 = extractUsersFromURI(p[:uri])
          partnership = self.new(client, user1, user2)
          list << partnership if !block_given? || yield(partnership)
        end
        break unless all
        start += size
        break if start >= total
      end
      list
    end

    def initialize(client, user1, user2, info={})
      @client = client
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
      @publicvisible = info[:publicvisible]
    end

    def update
      raise "Partnership not found" unless exist?
      response = if @client.authenticated?(@user1.username, @user1.password)
                   CoachClient::AuthenticatedRequest.get(url, @user1.username,
                                                         @user1.password)
                 elsif @client.authenticated?(@user2.username, @user2.password)
                   CoachClient::AuthenticatedRequest.get(url, @user2.username,
                                                         @user2.password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @id = response[:id]
      @datecreated = response[:datecreated]
      @publicvisible = response[:publicvisible]
      @user1_confirmed = response[:userconfirmed1]
      @user2_confirmed = response[:userconfirmed2]
      self
    end

    def save
      unless operational?
        propose unless @user1_confirmed
        return confirm
      end
      user1 = @client.authenticated?(@user1.username, @user1.password)
      user2 = @client.authenticated?(@user2.username, @user2.password) unless user1
      raise "Unauthorized" unless user1 || user2
      begin
        response = if user1
                     CoachClient::AuthenticatedRequest.put(url, @user1.username,
                                                           @user1.password,
                                                           payload,
                                                           content_type: :xml)
                   else
                     CoachClient::AuthenticatedRequest.put(url, @user2.username,
                                                           @user2.password,
                                                           payload,
                                                           content_type: :xml)
                   end
      rescue RestClient::Conflict
        raise "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise "Could not save partnership"
      end
      self
    end

    def propose
      unless @client.authenticated?(@user1.username, @user1.password)
        raise "Unauthorized"
      end
      begin
        response = CoachClient::AuthenticatedRequest.put(url, @user1.username,
                                                         @user1.password,
                                                         payload,
                                                         content_type: :xml)
      rescue RestClient::Conflict
        raise "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise "Could not propose partnership"
      end
      @user1_confirmed = true
      self
    end

    def confirm
      unless @client.authenticated?(@user2.username, @user2.password)
        raise "Unauthorized"
      end
      begin
        response = CoachClient::AuthenticatedRequest.put(url, @user2.username,
                                                         @user2.password,
                                                         payload,
                                                         content_type: :xml)
      rescue RestClient::Conflict
        raise "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise "Could not confirm partnership"
      end
      @user2_confirmed = true
      self
    end

    def invalidate
      raise "Unauthorized" unless @client.authenticated?(@user2.username,
                                                         @user2.password)
      CoachClient::AuthenticatedRequest.delete(url, @user2.username,
                                               @user2.password)
      @user2_confirmed = false
      true
    end

    def delete
      invalidate if operational?
      raise "Unauthorized" unless @client.authenticated?(@user1.username,
                                                         @user1.password)
      CoachClient::AuthenticatedRequest.delete(url, @user1.username,
                                               @user1.password)
      @user1_confirmed = false
      true
    end

    def operational?
      @user1_confirmed && @user2_confirmed
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
      "#{@client.url}#{self.class.path}#{@user1.username};#{@user2.username}"
    end

    def to_h
      hash = {}
      instance_variables.each do |var|
        next if var.to_s == '@client'
        value = instance_variable_get(var)
        hash[var.to_s.delete('@').to_sym] = if value && value.respond_to?(:to_h)
                                              value.to_h
                                            else
                                              value
                                            end
      end
      hash
    end

    def to_s
      "#{@user1.username};#{@user2.username}"
    end

    private

    def self.extractUsersFromURI(uri)
      match = uri.match(/partnerships\/(\w+);(\w+)\//)
      match.captures
    end

    def payload
      vals = self.to_h
      vals.delete(:user1)
      vals.delete(:user2)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      Gyoku.xml(partnership: vals)
    end
  end
end

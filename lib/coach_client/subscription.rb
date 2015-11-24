module CoachClient
  class Subscription
    attr_reader :id, :datesubscribed
    attr_accessor :client, :user, :sport, :publicvisible

    def self.path
      'users/'
    end

    def initialize(client, user, sport, info={})
      @client = client
      @user = if user.is_a?(CoachClient::User)
                user
              else
                CoachClient::User.new(client, user)
              end
      @sport = if sport.is_a?(CoachClient::Sport)
                 sport
               else
                 CoachClient::Sport.new(client, sport)
               end
      @publicvisible = info[:publicvisible]
    end

    def update
      raise "Subscription not found" unless exist?
      response = if @client.authenticated?(@user.username, @user.password)
                   CoachClient::AuthenticatedRequest.get(url, @user.username,
                                                         @user.password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @id = response[:id]
      @datesubscribed = response[:datesubscribed]
      @publicvisible = response[:publicvisible]
      self
    end

    def save
      vals = self.to_h
      vals.delete(:user)
      vals.delete(:sport)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      payload = Gyoku.xml(subscription: vals)
      unless @client.authenticated?(@user.username, @user.password)
        raise "Unauthorized"
      end
      begin
        response = CoachClient::AuthenticatedRequest.put(url, @user.username,
                                                         @user.password, payload,
                                                         content_type: :xml)
      rescue RestClient::Conflict
        raise "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise "Could not save subscription"
      end
      @password = vals[:password]
      @newpassword = nil
      self
    end

    def delete
      raise "Unauthorized" unless @client.authenticated?(@user.username,
                                                         @user.password)
      CoachClient::AuthenticatedRequest.delete(url, @user.username,
                                               @user.password)
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
      "#{@client.url}#{self.class.path}#{@user.username}/#{@sport.to_s}"
    end

    def to_h
      hash = {}
      instance_variables.each do |var|
        next if var.to_s == '@client'
        value = instance_variable_get(var)
        hash[var.to_s.delete('@').to_sym] = if value.respond_to?(:to_h)
                                              value.to_h
                                            else
                                              value
                                            end
      end
      hash
    end

    def to_s
      "#{@user.username.to_s}/#{@sport.to_s}"
    end
  end
end


module CoachClient
  class Entry < Resource
    attr_reader :id, :datecreated, :datemodified
    attr_accessor :publicvisible, :subscription, :comment,
      :entrydate, :entryduration, :entrylocation

    def self.extractIdFromURI(uri)
      match = uri.match(/\/(\d+)\/\z/)
      match.captures.first
    end

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

    def update
      raise CoachClient::NotFound, "Entry not found" unless exist?
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
      self
    end

    def create
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), "Unauthorized"
      end
      begin
        response = CoachClient::Request.post(@subscription.url,
                                             username: user.username,
                                             password: user.password,
                                             payload: payload,
                                             content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), "Could not create entry"
      end
      @id = self.class.extractIdFromURI(response.header[:location])
      self
    end

    def save
      return create unless @id
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), "Unauthorized"
      end
      begin
        response = CoachClient::Request.put(url, username: user.username,
                                            password: user.password,
                                            payload: payload,
                                            content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), "Could not save entry"
      end
      self
    end

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

    def delete
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), "Unauthorized"
      end
      CoachClient::Request.delete(url, username: user.username,
                                  password: user.password)
      true
    end

    def exist?(username: nil, password: nil)
      return false unless @id
      if @client.authenticated?(user.username, user.password)
        super(username: user.username, password: user.password)
      else
        super
      end
    end

    def url
      "#{@subscription.url}/#{@id}"
    end

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


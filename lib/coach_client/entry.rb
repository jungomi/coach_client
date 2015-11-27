module CoachClient
  class Entry
    attr_reader :id, :datecreated, :datemodified
    attr_accessor :client, :publicvisible, :subscription

    def initialize(client, subscription, id, info={})
      @client = client
      @subscription = subscription
      @id = id
      @publicvisible = info[:publicvisible]
    end

    def update
      raise "Entry not found" unless exist?
      response = if @client.authenticated?(user.username, user.password)
                   CoachClient::AuthenticatedRequest.get(url, user.username,
                                                         user.password)
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

    def save
      raise "Entry not found" unless exist?
      vals = self.to_h
      vals.delete(:subscription)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      tag = "entry#{@subscription.sport}"
      payload = Gyoku.xml(tag.to_sym => vals)
      unless @client.authenticated?(user.username, user.password)
        raise "Unauthorized"
      end
      begin
        response = CoachClient::AuthenticatedRequest.put(url, user.username,
                                                         user.password, payload,
                                                         content_type: :xml)
      rescue RestClient::Conflict
        raise "Incomplete information"
      end
      unless response.code == 200 || response.code == 201
        raise "Could not save subscription"
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
      raise "Unauthorized" unless @client.authenticated?(user.username,
                                                         user.password)
      CoachClient::AuthenticatedRequest.delete(url, user.username,
                                               user.password)
      true
    end

    def exist?
      begin
        CoachClient::AuthenticatedRequest.get(url, user.username, user.password)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

    def url
      "#{@subscription.url}/#{@id}"
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
  end
end

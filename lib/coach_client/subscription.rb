module CoachClient
  class Subscription
    attr_reader :id, :datesubscribed, :entries
    attr_accessor :client, :sport, :publicvisible

    def initialize(client, sport, info={})
      @client = client
      @sport = if sport.is_a?(CoachClient::Sport)
                 sport
               else
                 CoachClient::Sport.new(client, sport)
               end
      @publicvisible = info[:publicvisible]
    end

    def exist?
      begin
        CoachClient::Request.get(url)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

    def to_h
      hash = {}
      instance_variables.each do |var|
        next if var.to_s == '@client'
        value = instance_variable_get(var)
        hash[var.to_s.delete('@').to_sym] = if value && value.respond_to?(:to_h) && !value.is_a?(Array)
                                              value.to_h
                                            else
                                              value
                                            end
      end
      hash
    end

    protected

    def update(user)
      raise "Subscription not found" unless exist?
      response = if @client.authenticated?(user.username, user.password)
                   CoachClient::AuthenticatedRequest.get(url, user.username,
                                                         user.password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @id = response[:id]
      @datesubscribed = response[:datesubscribed]
      @publicvisible = response[:publicvisible]
      @entries = []
      response[:entries].each do |e|
        tag = "entry#{@sport}"
        id = e[tag.to_sym][:uri].match(/\/(\d+)\/\z/).captures.first
        @entries << CoachClient::Entry.new(client, self, id: id)
      end
      self
    end

    def save(user)
      vals = self.to_h
      vals.delete(:user)
      vals.delete(:partnership)
      vals.delete(:sport)
      vals.delete_if { |_k, v| v.nil? || v.to_s.empty? }
      payload = Gyoku.xml(subscription: vals)
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

    def delete(user)
      raise "Unauthorized" unless @client.authenticated?(user.username,
                                                         user.password)
      CoachClient::AuthenticatedRequest.delete(url, user.username,
                                               user.password)
      true
    end
  end
end


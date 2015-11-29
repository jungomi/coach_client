module CoachClient
  class Subscription < Resource
    attr_reader :id, :datesubscribed, :entries
    attr_accessor :sport, :publicvisible

    def initialize(client, sport, publicvisible: nil)
      super(client)
      @sport = if sport.is_a?(CoachClient::Sport)
                 sport
               else
                 CoachClient::Sport.new(client, sport)
               end
      @publicvisible = publicvisible
    end

    protected

    def update(user)
      raise CoachClient::NotFound, 'Subscription not found' unless exist?
      response = if @client.authenticated?(user.username, user.password)
                   CoachClient::Request.get(url, username: user.username,
                                            password: user.password)
                 else
                   CoachClient::Request.get(url)
                 end
      response = response.to_h
      @id = response[:id]
      @datesubscribed = response[:datesubscribed]
      @publicvisible = response[:publicvisible]
      @entries = []
      unless response[:entries].nil?
        response[:entries].each do |e|
          tag = "entry#{@sport}"
          id = CoachClient::Entry.extract_id_from_uri(e[tag.to_sym][:uri])
          @entries << CoachClient::Entry.new(client, self, id: id)
        end
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
        raise CoachClient::Unauthorized.new(user), 'Unauthorized'
      end
      begin
        response = CoachClient::Request.put(url, username: user.username,
                                            password: user.password,
                                            payload: payload,
                                            content_type: :xml)
      rescue RestClient::Conflict
        raise CoachClient::IncompleteInformation.new(self), 'Incomplete information'
      end
      unless response.code == 200 || response.code == 201
        raise CoachClient::NotSaved.new(self), 'Could not save subscription'
      end
      self
    end

    def delete(user)
      unless @client.authenticated?(user.username, user.password)
        raise CoachClient::Unauthorized.new(user), 'Unauthorized'
      end
      CoachClient::Request.delete(url, username: user.username,
                                  password: user.password)
      true
    end
  end
end


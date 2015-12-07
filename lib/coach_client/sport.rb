module CoachClient
  class Sport < Resource
    attr_reader :sport, :id, :name, :description

    def self.path
      'sports/'
    end

    def self.total(client)
      response = CoachClient::Request.get(client.url + path,
                                          params: { size: 0 })
      response.to_h[:available]
    end

    def self.list(client)
      sportlist  = []
      response = CoachClient::Request.get(client.url + path)
      response.to_h[:sports].each do |s|
        sport = self.new(client, s[:name])
        sportlist << sport if !block_given? || yield(sport)
      end
      sportlist
    end

    def initialize(client, sport)
      super(client)
      @sport = sport.downcase.to_sym
    end

    def update
      raise CoachClient::NotFound, 'Sport not found' unless exist?
      response = CoachClient::Request.get(url)
      response = response.to_h
      @id = response[:id]
      @name = response[:name]
      @description = response[:description]
      self
    end

    def url
      @client.url + self.class.path + @sport.to_s
    end

    def to_s
      @sport.to_s
    end
  end
end


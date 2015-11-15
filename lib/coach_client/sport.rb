module CoachClient
  class Sport
    attr_reader :sport
    attr_accessor :client, :id, :name, :description

    def self.path
      'sports/'
    end

    def initialize(client, sport)
      @client = client
      @sport = sport.downcase.to_sym
    end

    def update
      raise "Sport not found" unless exist?
      response = CoachClient::Request.get(url)
      response = response.to_h
      @id = response[:id]
      @name = response[:name]
      @description = response[:description]
      self
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
      @client.url + self.class.path + @sport.to_s
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
      @sport.to_s
    end
  end
end

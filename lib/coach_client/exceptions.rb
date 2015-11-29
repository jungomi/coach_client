module CoachClient
  class NotFound < StandardError; end

  class NotSaved < StandardError
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end
  end

  class NotConfirmed < StandardError
    attr_reader :partnership

    def initialize(partnership)
      @partnership = partnership
    end
  end

  class NotProposed < StandardError
    attr_reader :partnership

    def initialize(partnership)
      @partnership = partnership
    end
  end

  class Unauthorized < StandardError
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end
  end

  class IncompleteInformation < StandardError
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end
  end
end

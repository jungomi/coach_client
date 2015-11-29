module CoachClient
  class Exception < StandardError; end

  class NotFound < Exception; end

  class NotSaved < Exception
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end
  end

  class NotConfirmed < Exception
    attr_reader :partnership

    def initialize(partnership)
      @partnership = partnership
    end
  end

  class NotProposed < Exception
    attr_reader :partnership

    def initialize(partnership)
      @partnership = partnership
    end
  end

  class Unauthorized < Exception
    attr_reader :user

    def initialize(user = nil)
      @user = user
    end
  end

  class IncompleteInformation < Exception
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end
  end
end

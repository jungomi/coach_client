module CoachClient
  # The standard exception for CoachClient errors.
  class Exception < StandardError; end

  # The error when the resource could not be found on the CyberCoach service.
  class NotFound < CoachClient::Exception; end

  # The error for resources that could not have been saved.
  class NotSaved < CoachClient::Exception
    # Returns the resource that encountered the error.
    #
    # @return [CoachClient::Resource]
    attr_reader :resource

    # @param [CoachClient::Resource] resource
    # @return [CoachClient::NotSaved]
    def initialize(resource)
      @resource = resource
    end
  end

  # Returns the error for partnerships that could not be confirmed.
  class NotConfirmed < CoachClient::Exception
    # Returns the partnership that encountered the error.
    #
    # @return [CoachClient::Partnership]
    attr_reader :partnership

    # @param [CoachClient::Partnership] partnership
    # @return [CoachClient::NotConfirmed]
    def initialize(partnership)
      @partnership = partnership
    end
  end

  # The error for partnerships that could not be proposed.
  class NotProposed < CoachClient::Exception
    # Returns the partnership that encountered the error.
    #
    # @return [CoachClient::Partnership]
    attr_reader :partnership

    # @param [CoachClient::Partnership] partnership
    # @return [CoachClient::NotProposed]
    def initialize(partnership)
      @partnership = partnership
    end
  end

  # The error that the user is not authorized to see the resource.
  class Unauthorized < CoachClient::Exception
    # Returns the user that encountered the error.
    #
    # @return [CoachClient::User]
    attr_reader :user

    # @param [CoachClient::User] user
    # @return [CoachClient::Unauthorized]
    def initialize(user = nil)
      @user = user
    end
  end

  # The error for missing informations of a resource.
  class IncompleteInformation < CoachClient::Exception
    # Returns the resource that encountered the error.
    #
    # @return [CoachClient::Resource]
    attr_reader :resource

    # @param [CoachClient::Resource] resource
    # @return [CoachClient::IncompleteInformation]
    def initialize(resource)
      @resource = resource
    end
  end
end

# CoachClient
[![Gem Version](https://badge.fury.io/rb/coach_client.svg)](https://badge.fury.io/rb/coach_client)

A wrapper around the
[CyberCoach](https://diuf.unifr.ch/drupal/softeng/teaching/studentprojects/cyber-coach-rest)
API of the University of Fribourg.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coach_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coach_client

## Documentation

- [Rubygem website](https://rubygems.org/gems/coach_client)
- [Documentation](http://www.rubydoc.info/gems/coach_client/0.1.0)
- [GitHub](https://github.com/jungomi/coach_client)

## Usage

### Client

Every action to a CyberCoach service requires a client. The client contains the
URL to the service and provides some methods to retrieve resources.

```ruby
client = CoachClient::Client.new('http://diufvm31.unifr.ch:8090',
                                 '/CyberCoachServer/resources/')
```

### Resources

All CyberCoach resources follow the same basic principles.
- `save` saves the resource on the CyberCoach service (creates or overwrites it).
- `update` updates the resource with the data from CyberCoach service (fetch).
- `delete` deletes the resource on the CyberCoach service.
- `exist?` returns whether the resource exists on the CyberCoach service.

#### User

A user is identified by the username which has to be specified on creation.

```ruby
user = CoachClient::User.new(client, 'myusername')
```

All the attributes of the user can be accessed and changed directly

```ruby
user.username                #=> "myusername"
user.password                #=> nil
user.password = 'mypassword' #=> "mypassword"
```

Or the attributes can be supplied as optional arguments on creation

```ruby
user = CoachClient::User.new(client, 'myusername', password: 'mypassword')
user.username #=> "myusername"
user.password #=> "mypassword"
```

A list of users can be obtained with the class method `list`. It takes an
optional block, which acts as a filter and therefore only returns the users for
which the block returns a true value. If the block is omitted, the whole list is
returned.  
The list is divided into chunks by the CyberCoach service. To retrieve the
complete list the optional parameter `all` can be set to true.  
As the user informations are not provided in the list, each user has to be
updated individually in order to apply filtering on them. **This requires a GET
request every time**.

```ruby
# lists only the users with a username with less than 5 characters
CoachClient::User.list(client) { |user| user.username.length < 5 }

# lists all available users
CoachClient::User.list(client, all: true)

# lists only the users with an email address ending with '.ch'
CoachClient::User.list(client) do |user|
  user.update # required to retrieve email address
  user.email.end_with?('.ch')
end
```

To verify if the credentials are valid the method `authenticated?` is used.
If credentials need to be tested without having to create a new user, the
method in the client can be used.

```ruby
user.authenticated? #=> true

client.authenticated?('myusername', 'mypassword') #=> true
```

#### Partnership

A partnership is a relationship between two users. The users can be passed as
`CoachClient::User` objects. If this it not the case, it tries to create them.  
Passing a user object is recommended because it contains the already established
informations (most importantly the password, which is needed for some requests).
The users can be accessed and changed accordingly.

```ruby
# partnership between the user created above and a user with the username 'mypartner'
partnership = CoachClient::Partnership.new(client, user, 'mypartner')

# set password of 'mypartner'
partnership.user2.password = 'hispassword'
```

The partnership provides a class method `list` is used to obtain a list of
partnerships, which works the same way as the `User.list`.

```ruby
# lists only the partnerships for which user1 is 'myusername' and the 
# user2 has confirmed the partnership.
CoachClient::Partnership.list(client) do |partnership|
  return false unless partnership.user1.username == 'myusername'
  partnership.update # only update when the first condition succeeded
  partnership.user2_confirmed
end
```

To obtain the partnerships of a specific user, use the partnerships attribute of
the user, instead of traversing the entire list. Even though the partnership
on the CyberCoach service does not always provide the user that had done the
request as the first user in the partnership, the list of partnerships returned
ensures that `user1 == user`.

```ruby
user.update # needed to get the partnerships from the CyberCoach service
user.partnerships

user.partnerships.all? { |partnership| partnership.user1 == user } #=> true
```

The partnership uses the following methods to modify its status:
- `propose` proposes a partnership by user1
- `confirm` confirms a partnership by user2
- `invalidate` invalidates the confirmations of user2

When using `save` on a partnership that is not operational, it first tries to
propose and confirm it. Similarly `delete` will try to invalidate it before
deleting it.

#### Sport

The sport resource cannot be modified on the CyberCoach service and therefore
the methods `save` and `delete` are not supported.  
The sports are identified by a `Symbol` of their names. On creation the name is
converted into a symbol. The name is case insensitive.

```ruby
sport  = CoachClient::Sport.new(client, :running)
sport2 = CoachClient::Sport.new(client, 'running')
sport3 = CoachClient::Sport.new(client, 'RUnNinG')

sport.sport  #=> :running
sport2.sport #=> :running
sport3.sport #=> :running
```

The list of sports can be obtained with the class method `list` in the same
manner as the users and partnerships.

#### Subscription

A subscription consists of sport and either a user or a partnership. For that
matter use `CoachClient::UserSubscription` and
`CoachClient::PartnershipSubscription` respectively. They are essentially the
same besides the subject being a user or a partnership and can therefore be
used almost identically.

As for the other resources the user or partnership and the sport may be passed
as the corresponding object. When an argument is not the object, it tries to
create it. For partnerships a string representation is expected in that case,
which represents the two users involved separated by a semicolon.
Using already existing objects is recommended to preserve the already assigned
attributes.

```ruby
user_sub = CoachClient::UserSubscription.new(client, user, sport)
part_sub = CoachClient::PartnershipSubscription.new(client, partnership, sport)
```

To retrieve the subscriptions of a particular user or partnership, the
subscriptions attribute of the respective object is used.

```ruby
user.update # needed to get the subscriptions from the CyberCoach service
user.subscriptions

partnership.update # needed to get the subscriptions from the CyberCoach service
partnership.subscriptions
```

#### Entry

An entry corresponds to subscription. The entry provides the method `create` to
create a new entry. This is automatically invoked when trying to save it, if the
entry does not exist on the CyberCoach service. When create is used on an
already existing entry, it creates a new one with the same attributes (apart
from the id).

```ruby
entry = CoachClient::Entry.new(client, user_sub, publicvisible: 2, comment: 'my comment')

entry.exist?  #=> false
entry.save
entry.id      #=> 1
entry.comment #=> 'my comment'
entry.exist?  #=> true

entry.create
entry.id      #=> 2
entry.comment #=> 'my comment'
```

To see all entries of a subscription use the attribute entries of the
subscription.

```ruby
user_sub.update # needed to get the entries from the CyberCoach service
user.entries
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/jungomi/coach_client).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


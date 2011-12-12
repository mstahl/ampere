# Ampere — A Redis ORM for Ruby

Ampere is an ActiveRecord-style ORM for the Redis key/value data store. 

This is under active development right now and not very far along. Stay
tuned for further developments.

## Usage

Write a model class and make it inherit from the `Ampere::Model` class.
These work pretty similarly to how they do in ActiveRecord or Mongoid.

    class Car < Ampere::Model
      field :make
      field :model
      field :year

      has_one :engine
      has_many :passengers
    end

    class Engine < Ampere::Model
      field :displacement
      field :cylinders
      field :configuration
      
      belongs_to :car
    end
    
    class Passenger < Ampere::Model
      field :name
      field :seat
      
      belongs_to :car
    end

This will define attr accessors for each field. Then to instantiate it,

    Post.new :title    => "BREAKING: Kitties Are Awesome", 
             :contents => "This just in! Kitties are super adorable, and super great."

Later, when you want to retrieve it, you can use the where() method (although this will
be slower if one of the keys you are searching by isn't indexed).

    post = Post.where(:title => "BREAKING: Kitties Are Awesome").first

### Indexes

Indexes work similar to Mongoid. They are non-unique.

    class Student < Ampere::Model
      field :last_name
      field :first_name
      
      index :last_name
    end

This will create an index of the last names of students, and lookups by
last_name will happen faster.

## Contributing to ampere
 
  * Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
  * Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
  * Fork the project
  * Start a feature/bugfix branch
  * Commit and push until you are happy with your contribution
  * Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
  * Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Max Thom Stahl. See LICENSE.txt for further details.


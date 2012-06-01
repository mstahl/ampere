# Ampere — A Redis ORM for Ruby

Ampere is an ActiveRecord-style ORM for the Redis key/value data store. 

## A note about Ampere version >1.0 (IMPORTANT!!!)

For the 1.0 release I changed Ampere's API so that instead of subclassing
`Ampere::Model` to use Ampere's methods, you include it as a mixin. This
change has been reflected in the examples below.

This change was to unify the usage of Ampere a little more with usage of
Mongoid, and also so that users of Ampere can use their own class hierarchies,
which at some later date might have significance with how Ampere works.

## Usage

Write a model class and make it inherit from the `Ampere::Model` class.
These work pretty similarly to how they do in ActiveRecord or Mongoid.

    class Car
      include Ampere::Model
      
      field :make
      field :model
      field :year

      has_one :engine
      has_many :passengers
    end

    class Engine
      include Ampere::Model
      
      field :displacement
      field :cylinders
      field :configuration
      
      belongs_to :car
    end
    
    class Passenger
      include Ampere::Model
      
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

Ampere query results implement the `Enumerable` module, so all the Enumerable methods 
you know and love are there. 

### Indexes

Indexes work similar to Mongoid. They are non-unique by default.

    class Student
      include Ampere::Model
      
      field :last_name
      field :first_name
      
      index :last_name
    end

This will create an index of the last names of students, and lookups by
last_name will happen faster.

You can also define indices on multiple fields.
    
    class Student
      include Ampere::Model
      
      field :last_name
      field :first_name
      
      index [:last_name, :first_name]
    end

Queries performed on compound indices will always run faster than queries on multiple
individual indices, which will always run faster than queries on unindexed fields. 

_**Warning:**_ If you query on an un-indexed field, the returned result set will not be
evaluated lazily!

### Validations

You can now add validations to your Ampere models thanks to the magic of ActiveModel!

    class Student
      include Ampere::Model
      
      field :last_name
      field :first_name
      field :student_id_number
      
      index [:last_name, :first_name]
      
      validates_presence_of :last_name
      validates_format_of :student_id_number, :with => /\A[0-9]{10}\Z/
    end

It's that easy!

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


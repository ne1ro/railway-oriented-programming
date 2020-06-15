#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'awesome_print'
require 'dry/monads'
require 'dry/monads/do'

User = Struct.new(:address)
Address = Struct.new(:country, :street)
Country = Struct.new(:name)

# The Maybe monad is used when a series of computations could return nil at any point.
class FetchCountryName
  include Dry::Monads[:maybe]
  include Dry::Monads::Do.for(:call)

  attr_reader :user
  private :user

  def initialize(user)
    @user = user
  end

  # @return [Some, None]
  def call
    address = yield Maybe(user.address)
    country = yield Maybe(address.country)

    Maybe(country.name)
  end

  # Equals call - but without do notation
  # @return [Some, None]
  def call_bindings
    Maybe(user).bind do |u|
      Maybe(u.address) do |a|
        Maybe(a.country) do |c|
          Maybe(c.name)
        end
      end
    end
  end
end

puts 'All fields are present'

country = Country.new('Germany')
address = Address.new(country, 'Beispielstrasse')
user = User.new(address)
ap FetchCountryName.new(user).call

puts 'Address is not there'
user = User.new(nil)
ap FetchCountryName.new(user).call

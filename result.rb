#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'awesome_print'
require 'dry/monads'
require 'dry/monads/do'
require 'optparse'

# Parse options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: monads.rb [options]'

  opts.on('-nNAME', '--name=NAME', 'User name') do |name|
    options[:name] = name
  end

  opts.on('-eEMAIL', '--email=EMAIL', 'User email') do |email|
    options[:email] = email
  end
end.parse!

User = Struct.new(:email, :name)

# Users database operations
class UsersRepo
  include Dry::Monads[:result]

  def save(user)
    Success(user)
  end
end

# Users email notifications
class Notifier
  include Dry::Monads[:result]

  INVALID_DOMAIN = /^.*@invalidated.com$/.freeze

  def send_notification(user)
    return Failure(:invalid_email_domain) if INVALID_DOMAIN =~ user.email

    notification = { text: "Hello, #{user.name}", email: user.email }
    Success(notification)
  end
end

# User sign up use case
class SignUp
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  attr_reader :email, :name, :users_repo, :notifier
  private :email, :name, :users_repo, :notifier

  EMAIL_VALIDATION = /^.+@.+$/.freeze
  NAME_VALIDATION = /^[A-z]+$/.freeze

  def initialize(email:, name:)
    @email = email
    @name = name
    @users_repo = UsersRepo.new
    @notifier = Notifier.new
  end

  def call
    yield validate_email(email)
    yield validate_name(name)

    user = User.new(email, name)

    yield users_repo.save(user)
    notification = yield notifier.send_notification(user)

    Success([user, notification])
  end

  # Equals call - but without do notation
  def call_bindings
    validate_email(email).bind do
      validate_name(name).bind do
        user = User.new(email, name)

        users_repo.save(user).bind do
          notifier.send_notification(user).fmap do |notification|
            [user, notification]
          end
        end
      end
    end
  end

  private

  def validate_email(email)
    return Failure(:invalid_email_format) unless EMAIL_VALIDATION =~ email

    Success(email)
  end

  def validate_name(name)
    return Failure(:invalid_name) unless NAME_VALIDATION =~ name

    Success(name)
  end
end

result = SignUp.new(**options).call_bindings

# Pattern-match the result
case result
  in Dry::Monads::Result::Failure(:invalid_email_domain)
  puts "Can't send an email to this domain :( "

  in Dry::Monads::Result::Failure(message)
  puts 'Failed with message:'
  ap message

  in Dry::Monads::Result::Success[user, notification]
  puts 'Signed up user:'
  ap user
  puts 'Sent notification:'
  ap notification
end

ENV["ENVIRONMENT"] = "test"

require "rubygems"
require "bundler/setup"

require "minitest/autorun"
require File.dirname(__FILE__) + "/../lib/redis_directory"
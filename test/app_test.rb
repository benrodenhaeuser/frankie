ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require 'fileutils'

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Frankie::Application
  end

  def test_some_route
    get "/some_route"
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h1>Frankie says hello!</h1>'
  end
end

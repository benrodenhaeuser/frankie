ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Frankie::Application
  end

  def test_redirect_from_root
    get "/"
    assert_equal 302, last_response.status
  end
end

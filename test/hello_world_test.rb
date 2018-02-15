ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../hello_world"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Frankie::Application
  end

  def test_root
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'hello'
  end
end

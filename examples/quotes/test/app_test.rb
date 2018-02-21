ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require 'erb'

require_relative "../app"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Frankie::Application
  end

  def test_get_root
    get "/"
    assert_equal 302, last_response.status
    assert_equal "text/html", last_response["Content-Type"]
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'famously said'
  end

  def test_get_index
    get "/quotes"
    assert_equal 200, last_response.status
    assert_equal "text/html", last_response["Content-Type"]
    assert_includes last_response.body, 'famously said'
  end

  def test_get_new_quote
    get "/quotes/new"
    assert_equal 200, last_response.status
    assert_equal "text/html", last_response["Content-Type"]
    assert_includes last_response.body, 'Author'
    assert_includes last_response.body, '<form'
  end

  def test_post_new_quote
    post(
      "/quotes",
      { 'author' => 'Tom', 'quote' => 'Some nonsense.' }
    )
    assert_equal 303, last_response.status
    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'The quote has been added.'
  end
end

# config.ru

require 'rack'
require_relative 'app'

Rack::Handler::WEBrick.run Baby::App

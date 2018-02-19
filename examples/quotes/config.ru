require './app'

use Rack::Session::Cookie, :key => 'rack.session', :secret => "secret"
run Frankie::Application

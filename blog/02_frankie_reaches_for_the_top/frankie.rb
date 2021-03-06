require 'rack'

module Frankie
  module BookKeeping
    VERSION = 0.2
  end

  class Application
    class << self
      def call(env)
        new.call(env)
      end

      def routes
        @routes ||= []
      end

      def get(path, &block)
        route('GET', path, block)
      end

      def post(path, &block)
        route('POST', path, block)
      end

      def route(verb, path, block)
        routes << {
          verb:  verb,
          path:  path,
          block: block
        }
      end
    end

    def call(env)
      @request  = Rack::Request.new(env)
      @verb     = @request.request_method
      @path     = @request.path_info

      @response = {
        status:  200,
        headers: headers,
        body:    []
      }

      route!

      @response.values
    end

    def status(code)
      @response[:status] = code
    end

    def headers
      @headers ||= { 'Content-Type' => 'text/html' }
    end

    def body(string)
      @response[:body] = [string]
    end

    def route!
      match = Application.routes
                         .select { |route| route[:verb] == @verb }
                         .find   { |route| route[:path] == @path }
      return status(404) unless match

      body instance_eval(&match[:block])
    end
  end

  module Delegator
    def self.delegate(method_name)
      define_method(method_name) do |*args, &block|
        Application.send(method_name, *args, &block)
      end
    end

    delegate(:get)
    delegate(:post)
  end
end

extend Frankie::Delegator

# example:

get('/ditty') do
  status 301
  'Moved permanenly.'
end

Rack::Handler::WEBrick.run Frankie::Application

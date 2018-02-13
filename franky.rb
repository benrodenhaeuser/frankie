require 'rack'

module Franky
  class Application
    @routes = {}

    def call(env)
      @request = Rack::Request.new(env)
      verb = @request.request_method
      path = @request.path_info

      routes = self.class.routes
      match = nil

      routes[verb].each do |route|
        break match = route if route[:path] = path
      end
      result = instance_eval(&match[:block])
      # ^ Sinatra uses invoke { route_eval } here, and route_eval uses class_eval (I think) rather than instance_eval. Not sure what is going on.

      [200, {}, [result]] # we assume that result is a string here
    end

    class << self
      attr_reader :routes

      def get(path, &block)
        route('GET', path, &block)
      end

      def route(verb, path, &block)
        @routes ||= {}
        @routes[verb] ||= []

        signature = { path: path, block: block }
        @routes[verb] << signature
        signature
      end

      def call(env)
        new.call(env)
      end
    end
  end

  module Delegator
    def self.delegate(method)
      define_method(method) do |path, &block|
        Application.send(method, path, &block)
      end
    end

    delegate(:get)
  end

  at_exit { Rack::Handler::WEBrick.run Franky::Application, Port: 9292 }
end

extend Franky::Delegator # make delegated methods available to main


# FEATURES
# - can store get routes (and other types are easy to add now)
# - can respond to HTTP requests
# - uses Sinatra syntax for top-level methods

# MISSING
# - route parameters
# - call should be an instance method
# - templates
# - one instance per request

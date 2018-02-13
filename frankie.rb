require 'rack'

module Franky
  class Application
    attr_reader :params

    def call(env)
      @request = Rack::Request.new(env)
      @params = @request.params

      verb = @request.request_method
      path = @request.path_info

      routes = self.class.routes

      # THIS IS WHAT WE WOULD LIKE TO DO:

      # routes[verb].each do |route|
      #
      #  if route[:pattern].match(path)
      #     write key-value pairs in route to params
      #     return instance_eval(&route[:block])
      #   end
      # end
      #
      # [404, {}, ['404']]

      match = nil

      routes[verb].each do |route|
        break match = route if route[:path] == path

      end

      if match
        result = instance_eval(&match[:block])
        [200, {}, [result]]
      else
        [404, {}, ['404']]
      end
    end

    def erb(template)
      path = "./views/#{template}.erb"
      content = File.read(path)
      ERB.new(content).result(binding)
    end

    class << self
      attr_reader :routes

      def get(path, &block)
        route('GET', path, &block)
      end

      def post(path, &block)
        route('POST', path, &block)
      end

      # TODO: parametrized routes
      def route(verb, path, &block)
        @routes ||= {}
        @routes[verb] ||= []

        signature = { path: path, block: block }

        # pattern, keys = parse(path)
        # signature = { pattern: pattern, keys: keys, block: block }

        @routes[verb] << signature
        signature
      end

      def parse(path)
        # convert the given path to a regex
        # retrieve keys from path (want to use them later)
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
    delegate(:post)
  end

  at_exit { Rack::Handler::WEBrick.run Franky::Application, Port: 9292 }
end

extend Franky::Delegator
# ^ extend adds Franky::Delegator to main, rather than to Object
# ^ (which would be undesirable)

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
      puts routes

      routes[verb].each do |route|
       if route[:pattern].match(path)
          # TODO: make keys available to params hash
          return [200, {}, [instance_eval(&route[:block])]]
        end
      end

      [404, {}, ['<h1>404</h1>']]
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

      def route(verb, path, &block)
        @routes ||= {}
        @routes[verb] ||= []
        pattern, keys = parse(path)
        signature = { pattern: pattern, keys: keys, block: block }
        @routes[verb] << signature
        signature
      end

      def parse(path)
        segments = path.split('/')
        keys = []

        segments.map! do |segment|
          if segment.start_with?(':')
            keys << segment[1..-1]
            "[a-z0-9]+"
          else
            segment
          end
        end

        [/\A#{segments.join('/')}\z/, keys]
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

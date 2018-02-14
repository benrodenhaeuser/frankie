require 'rack'

module Frankie
  class Application
    attr_reader :params

    def call(env)
      @request = Rack::Request.new(env)
      @params = @request.params

      verb = @request.request_method
      path = @request.path_info

      routes = self.class.routes

      routes[verb].each do |route|
        match = route[:pattern].match(path)
        if match
          params.merge!(route[:keys].zip(match.captures).to_h)
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
            "([^\/]+)"
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
  end

  at_exit { Rack::Handler::WEBrick.run Frankie::Application, Port: 9292 } unless ENV['RACK_ENV'] == 'test'
end

extend Frankie::Delegator
# ^ extend adds Franky::Delegator to main, rather than to Object
# ^ (which would happen if we included it)

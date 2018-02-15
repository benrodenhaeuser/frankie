require 'rack'

module Frankie
  class Application
    class << self
      def get(path, &block)
        route('GET', path, &block)
      end

      def post(path, &block)
        route('POST', path, &block)
      end

      def route(verb, path, &block)
        @routes ||= {}
        @routes[verb] ||= []
        pattern, keys = compile(path)
        signature = { pattern: pattern, keys: keys, block: block }
        @routes[verb] << signature
        signature
      end

      def routes
        @routes
      end

      def compile(path)
        segments = path.split('/', -1)
        keys = []
        
        segments.map! do |segment|
          if segment.start_with?(':')
            keys << segment[1..-1]
            "([^\/]+)"
          else
            segment
          end
        end
        pattern = Regexp.compile("\\A#{segments.join('/')}\\z")

        [pattern, keys]
      end

      def call(env)
        new.call(env)
      end
    end

    def call(env)
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
      @params = @request.params

      route!

      @response.finish
    end

    def params
      @params
    end

    def route!
      routes = self.class.routes
      verb = @request.request_method
      path = @request.path_info

      routes[verb].each do |route|
        match = route[:pattern].match(path)
        if match
          params.merge!(route[:keys].zip(match.captures).to_h)
          @response.body = [instance_eval(&route[:block])]
          return
        end
      end

      @response.status = 404
      @response.body = ['<h1>404</h1>']
    end

    def erb(template)
      path = "./views/#{template}.erb"
      content = File.read(path)
      ERB.new(content).result(binding)
    end
  end

  module Delegator
    def self.delegate(method)
      define_method(method) do |path, &block|
        Application.send(method, path, &block)
      end
    end

    delegate(:get); delegate(:post)
  end

  unless ENV['RACK_ENV'] == 'test'
    at_exit { Rack::Handler::WEBrick.run Frankie::Application, Port: 4567 }
  end
end

extend Frankie::Delegator

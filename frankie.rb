require 'rack'

module Frankie
  class Application
    attr_reader :params

    def call(env)
      @request = Rack::Request.new(env) # Sinatra has a custom Request class
      @params = @request.params # Sinatra makes an "indifferent hash"
      # Sinatra also creates a response object

      verb = @request.request_method
      path = @request.path_info

      routes = self.class.routes

      # this is our whole routing logic so far:
      # how does sinatra do it? it all starts with invoke { dispatch! }
      # which happens in the call! method
      routes[verb].each do |route|
        match = route[:pattern].match(path)
        if match
          params.merge!(route[:keys].zip(match.captures).to_h)
          return [200, {}, [instance_eval(&route[:block])]]
        end
      end

      [404, {}, ['<h1>404</h1>']]

      # at the end, Sinatra's `call` returns `@response.finish`, which produces
      # a Rack-compliant array from the response object.
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

      # does not work for "/"
      def route(verb, path, &block)
        @routes ||= {}
        @routes[verb] ||= []
        pattern, keys = compile(path)
        signature = { pattern: pattern, keys: keys, block: block }
        @routes[verb] << signature
        signature
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

        # use Regexp.compile instead.
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

    delegate(:get); delegate(:post)
  end

  unless ENV['RACK_ENV'] == 'test'
    at_exit { Rack::Handler::WEBrick.run Frankie::Application, Port: 4567 }
  end
end

extend Frankie::Delegator
# ^ extend adds Franky::Delegator to main, rather than to Object
# ^ (which would happen if we included it)

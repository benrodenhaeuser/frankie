# CHANGE: require rack
require 'rack'

module Frankie
  module BookKeeping
    VERSION = 0.7
  end

  module Templates
    def path_to_template(app_root, template)
      template_dir = File.expand_path('../views', app_root)
      "#{template_dir}/#{template}.erb"
    end

    def erb(template)
      b = binding
      app_root = caller_locations.first.absolute_path
      content = File.read(path_to_template(app_root, template))
      ERB.new(content).result(b)
    end
  end

  class App
    include Templates

    class << self
      def call(env)
        prototype.call(env)
      end

      def prototype
        @prototype ||= new
      end

      alias new! new

      def new
        instance = new!
        build(instance).to_app
      end

      def build(app)
        builder = Rack::Builder.new

        if @middleware
          @middleware.each do |middleware, args|
            builder.use(middleware, *args)
          end
        end

        builder.run app
        builder
      end

      def use(middleware, *args)
        (@middleware ||= []) << [middleware, args]
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
        pattern, keys = compile(path)

        routes << {
          verb:     verb,
          pattern:  pattern,
          keys:     keys,
          block:    block
        }
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

      # CHANGE: new method
      def run!
        Rack::Handler::WEBrick.run Frankie::App
      end
    end

    def params
      @params ||= {}
    end

    def session
      @env['rack.session']
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @env = env
      @verb     = env['REQUEST_METHOD']
      @path     = env['PATH_INFO']
      @response = { status: 200, headers: headers, body: [] }

      invoke { dispatch! }

      @response.values
    end

    def body(string)
      @response[:body] = [string]
    end

    def headers
      @headers ||= {}
    end

    def status(code)
      @response[:status] = code
    end

    def invoke
      caught = catch(:halt) { yield }

      if caught
        case caught
        when Integer then status caught
        when String then body caught
        else
          body *caught.pop
          status caught.shift
          headers.merge!(*caught)
        end
      end
    end

    def dispatch!
      route!
      not_found
    end

    # CHANGE: new method
    def halt(response = nil)
      throw :halt, response
    end

    # CHANGE: use new halt method
    def redirect(uri)
      headers['Location'] = uri
      code = (@verb == 'GET') ? 302 : 303
      halt code
    end

    # CHANGE: use new halt method
    def not_found
      halt [404, {}, ["<h1>404 Not Found</h1"]]
    end

    # CHANGE: use new halt method
    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:pattern].match(@path) }

      if match
        values = match[:pattern].match(@path).captures.to_a
        params.merge!(match[:keys].zip(values).to_h)
        halt instance_eval(&match[:block])
      end
    end
  end

  module Delegator
    def self.delegate(method_name)
      define_method(method_name) do |*args, &block|
        App.send(method_name, *args, &block)
      end
    end

    delegate(:get)
    delegate(:use)
  end

  # CHANGE: at_exit hook
  at_exit { App.run! }
end

extend Frankie::Delegator

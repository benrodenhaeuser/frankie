require 'rack'

module Frankie
  module Templates
    def path_to_template(app_root, template)
      template_dir = File.expand_path('../views', app_root)
      "#{template_dir}/#{template}.erb"
    end

    def erb(template)
      b = binding
      root = caller_locations.first.absolute_path
      content = File.read(path_to_template(root, template))
      ERB.new(content).result(b)
    end
  end

  class Response < Rack::Response
    def initialize
      super
      headers['Content-Type'] ||= 'text/html'
    end
  end

  class Application
    include Templates

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @request = Rack::Request.new(env)
      @response = Response.new

      invoke { dispatch! }

      @response.finish
    end

    def invoke
      res = catch(:halt) { yield }
      res = [res] if Integer === res || String === res
      if Array === res && Integer === res.first
        res = res.dup
        @response.status = res.shift
        unless res.empty?
          @response.body = res.pop
          @response.headers.merge!(*res)
        end
      elsif res.respond_to? :each
        @response.body = res
      end
      nil
    end

    def halt(response = nil)
      throw :halt, response
    end

    def dispatch!
      route!
      not_found
    end

    def route!
      routes = self.class.routes
      verb = @request.request_method

      return unless routes[verb]

      path = @request.path_info
      routes[verb].each do |route|
        match = route[:pattern].match(path)
        next unless match
        values = match.captures.to_a
        params.merge!(route[:keys].zip(values).to_h)
        halt instance_eval(&route[:block])
      end
    end

    def not_found
      halt [404, {}, ['<h1>404</h1>']]
    end

    def redirect(uri)
      @response.status =
        if @request.get?
          302
        else
          303
        end
      @response.headers['Location'] = uri
      halt
    end

    def params
      @request.params
    end

    def headers
      @response.headers
    end

    def session
      @request.session
    end

    class << self
      def routes
        @routes ||= {}
      end

      def get(path, &block)
        route('GET', path, &block)
      end

      def post(path, &block)
        route('POST', path, &block)
      end

      def route(verb, path, &block)
        routes[verb] ||= []
        pattern, keys = compile(path)
        signature = { pattern: pattern, keys: keys, block: block }
        routes[verb] << signature
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

        pattern = Regexp.compile("\\A#{segments.join('/')}\\z")
        [pattern, keys]
      end

      def prototype
        @prototype ||= new
      end

      def call(env)
        prototype.call(env)
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
    delegate(:use)
  end

  # unless ENV['RACK_ENV'] == 'test'
  #   at_exit { Rack::Handler::WEBrick.run Frankie::Application }
  # end
end

# Sinatra:
# at_exit { Application.run! if $!.nil? && Application.run? }

extend Frankie::Delegator

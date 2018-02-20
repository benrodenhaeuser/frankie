require 'rack'

module Frankie
  module Templates
    def erb(template, path = "./views/#{template}.erb")
      content = File.read(path)
      ERB.new(content).result(binding)
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
        Wrapper.new(build(instance).to_app, instance)
      end

      def build(app)
        builder = Rack::Builder.new

        (@middleware || []).each do |mw, args|
          builder.use(mw, *args)
        end

        builder.run app
        builder
      end

      def use(mw, *args)
        @prototype = nil
        (@middleware ||= []) << [mw, args]
      end
    end
  end

  class Wrapper
    def initialize(stack, instance)
      @stack = stack
      @instance = instance
    end

    def call(env)
      @stack.call(env)
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

  unless ENV['RACK_ENV'] == 'test'
    at_exit { Rack::Handler::WEBrick.run Frankie::Application }
  end
end

extend Frankie::Delegator

require 'rack'

module Frankie
  module BookKeeping
    VERSION = 0.6
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
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @request  = Rack::Request.new(env)
      @verb     = @request.request_method
      @path     = @request.path_info
      @response = { status: 200, headers: headers, body: [] }

      # CHANGE: we use invoke now
      invoke { dispatch! }

      @response.values
    end

    def params
      @request.params
    end

    def session
      @request.session
    end

    def body(string)
      @response[:body] = [string]
    end

    def headers
      @headers ||= { 'Content-Type' => 'text/html' }
    end

    def status(code)
      @response[:status] = code
    end

    # CHANGE: new method
    def invoke
      caught = catch(:halt) { yield }
      return unless caught

      case caught
      when Integer then status caught
      when String then body caught
      else
        body(*caught.pop)
        status caught.shift
        headers.merge!(*caught)
      end
    end

    def dispatch!
      route!
      not_found
    end

    def redirect(uri)
      status (@verb == 'GET' ? 302 : 303)
      headers['Location'] = uri
      throw :halt
    end

    def not_found
      status 404
      body "<h1>404 Not Found</h1"
      throw :halt
    end

    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:pattern].match(@path) }
      return unless match

      values = match[:pattern].match(@path).captures.to_a
      params.merge!(match[:keys].zip(values).to_h)
      throw :halt, instance_eval(&match[:block])
    end
  end

  module Delegator
    def self.delegate(method_name)
      define_method(method_name) do |*args, &block|
        App.send(method_name, *args, &block)
      end
    end

    delegate(:get)
    delegate(:post)
    delegate(:use)
  end
end

extend Frankie::Delegator

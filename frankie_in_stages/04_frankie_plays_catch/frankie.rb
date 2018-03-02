require 'erb'

module Frankie
  module BookKeeping
    VERSION = 0.4
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
        new.call(env)
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

    # CHANGE: changed method in 0.4:
    def call(env)
      @request  = Rack::Request.new(env)
      @verb     = @request.request_method
      @path     = @request.path_info
      @response = { status: 200, headers: headers, body: [] }

      # CHANGE: changed line in 0.4:
      catch(:halt) { dispatch! }

      @response.values
    end

    def params
      @request.params
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

    def dispatch!
      route!
      not_found
    end

    # CHANGE: new method in 0.4
    def redirect(uri)
      code = (@verb == 'GET') ? 302 : 303
      status code
      headers['Location'] = uri
      throw :halt
    end

    # CHANGE: new method in 0.4
    def not_found
      status 404
      body "<h1>404 Not Found</h1"
      throw :halt
    end

    # CHANGE in 0.4: not_found case handled separately, use throw
    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:pattern].match(@path) }

      if match
        values = match[:pattern].match(@path).captures.to_a
        params.merge!(match[:keys].zip(values).to_h)
        body(instance_eval(&match[:block]))
        # CHANGE in 0.4: new line
        throw :halt
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
    delegate(:post)
  end
end

extend Frankie::Delegator

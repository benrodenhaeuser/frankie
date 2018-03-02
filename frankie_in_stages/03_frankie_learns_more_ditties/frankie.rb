require 'erb'

module Frankie
  module BookKeeping
    VERSION = 0.3
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

      # CHANGE in 0.3: pattern and keys
      def route(verb, path, block)
        pattern, keys = compile(path)

        routes << {
          verb:     verb,
          pattern:  pattern,
          keys:     keys,
          block:    block
        }
      end

      # CHANGE in 0.3: new method
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
      @request  = Rack::Request.new(env)
      @verb     = @request.request_method
      @path     = @request.path_info
      @response = { status: 200, headers: headers, body: [] }

      route!

      @response.values
    end

    def params
      @request.params
    end

    def status(code)
      @response[:status] = code
    end

    def headers
      @headers ||= { 'Content-Type' => 'text/html' }
    end

    def body(string)
      @response[:body] = [string]
    end

    # CHANGE in 0.3: find block: match with pattern
    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:pattern].match(@path) }

      # CHANGE in 0.3: process captured groups
      if match
        values = match[:pattern].match(@path).captures.to_a
        params.merge!(match[:keys].zip(values).to_h)
        body(instance_eval(&match[:block]))
      else
        status(404)
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

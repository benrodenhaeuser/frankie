# CHANGE in 0.2: require erb
require 'erb'

module Frankie
  module BookKeeping
    VERSION = 0.2
  end

  # CHANGE in 0.2: new module
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

      def route(verb, path, block)
        routes << {
          verb:  verb,
          path:  path,
          block: block
        }
      end
    end

    def call(env)
      @verb     = env['REQUEST_METHOD']
      @path     = env['PATH_INFO']
      @response = { status: 200, headers: {}, body: [] }

      route!

      @response.values
    end

    def body(string)
      @response[:body] = [string]
    end

    def status(code)
      @response[:status] = code
    end

    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:path] == @path }

      # CHANGE in 0.2: `instance_eval`
      match ? body(instance_eval(&match[:block])) : status(404)
    end
  end

  # CHANGE in 0.2: new module
  module Delegator
    def self.delegate(method_name)
      define_method(method_name) do |*args, &block|
        App.send(method_name, *args, &block)
      end
    end

    delegate(:get)
  end
end

# CHANGE in 0.2: add `delegate` to main object
extend Frankie::Delegator

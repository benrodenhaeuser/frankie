module Frankie
  module BookKeeping
    VERSION = 0.1
  end

  class App
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
      @response = { status: 200, headers: headers, body: [] }

      route!

      @response.values
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

    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:path] == @path }

      match ? body(match[:block].call) : status(404)
    end
  end
end

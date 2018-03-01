# baby_frankie.rb

module Baby
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
        routes << { verb: verb, path: path, block: block }
      end
    end

    def call(env)
      @verb = env['REQUEST_METHOD']
      @path = env['PATH_INFO']
      @resp = { status: 200, headers: {}, body: [] }

      route!

      @resp.values
    end

    def route!
      match = App.routes
                 .select { |route| route[:verb] == @verb }
                 .find   { |route| route[:path] == @path }

      match ? @resp[:body] = [match[:block].call] : @resp[:status] = 404
    end
  end
end

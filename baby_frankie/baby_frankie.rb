# baby_frankie.rb

module BabyFrankie
  class Application
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

      [@resp[:status], @resp[:headers], @resp[:body]]
    end

    def route!
      match =
        self.class.routes
            .select { |route| route[:verb] == @verb }
            .find   { |route| route[:path] == @path }

      if match
        @resp[:body] = [match[:block].call]
      else
        @resp[:status] = 404
      end
    end
  end
end

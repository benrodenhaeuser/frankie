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

      def route(verb, path, &block)
        routes << { verb: verb, path: path, block: block}
      end
    end

    def call(env)
      @verb, @path = env['REQUEST_METHOD'], env['PATH_INFO']
      @response = { status: 200, headers: {}, body: []}

      route!

      [@response[:status], @response[:headers], @response[:body]]
    end

    def route!
      routes = self.class.routes.select { |route| route[:verb] == @verb }
      match = routes.find { |route| route[:path] == @path }

      @response[:status] = 404 unless match
      @response[:body] = [match[:block].call] if match
    end
  end
end

class Base
  def call(env)
    dup.call!(env)
  end

  def call!(env)
    # handling the request
  end

  self << class
    def call(env)
      prototype.call(env)
    end

    def prototype
      @prototype ||= new
    end

    alias new! new

    # build(instance) returns a Rack::Builder instance
    # to_app should be a method of Rack::Builder
    def new
      instance = new!
      Wrapper.new(build(instance).to_app, instance)
    end

    def build(app)
      builder = Rack::Builder.new
      setup_default_middleware(builder) # among others: Rails::Session::Cookie
      setup_middleware(builder) # custom middleware stored in @middleware array
      builder.run app
      builder
    end

    def use(middleware, *args, &block)
        @prototype = nil # ? prsmbly because we need to set up the app from scratch.
        @middleware << [middleware, args, block]
      end
  end
end

class Wrapper
  # stack = the middleware stack
  # instance = our Frankie app
  def initialize(stack, instance)
    @stack, @instance = stack, instance
  end

  def call(env)
    @stack.call(env)
  end
end

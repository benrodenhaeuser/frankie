class Base

  # this is where the request is handled
  def call!(env)
    # handling the request
  end

  # the app instance is cloned and the clone receives the call
  def call(env)
    dup.call!(env)
  end

  self << class
    # this is where the call from the server comes in
    # it is handed to the prototype
    def call(env)
      prototype.call(env)
    end

    # here, we create the prototype
    def prototype
      @prototype ||= new
    end

    # we alias the inherited new as new!
    alias new! new

    # we override the inherited new
    # here, we create the app fronted by its middleware, by calling build
    # on the instance. build(instance) returns a Builder instance, to_app turns it into ...?
    def new
      instance = new!
      Wrapper.new(build(instance).to_app, instance)
    end

    # build the app instance fronted by its middleware
    def build(app)
      builder = Rack::Builder.new

      @middleware.each do |middleware, args, block|
        builder.use(middleware, *args, &block)
      end

      builder.run app
      builder
    end

    # add middleware to be used by the app
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

  # protoype.call(env) ends up invoking call on the middleware stack (which presumably includes the app instance as its last component)
  def call(env)
    @stack.call(env)
  end
end

# questions:
# 1. it seems that sessions (cookies) are included in the pipeline by default
#    but activating still is a user setting, correct?
# 2. how does Rack::Builder work exactly?
#    - rack middleware is like a linked list. the head is the first middleware,
#      the tail is the app. every middleware piece knows about the next piece,
#      so it can `call(env)` it.
#    - to_app presumably gives us an entry point to the linked list.


module Rack
  class Builder
    def to_app
      app = @map ? generate_map(@run, @map) : @run
      fail "missing run or map statement" unless app
      app = @use.reverse.inject(app) { |a,e| e[a] }
      @warmup.call(app) if @warmup
      app
    end
  end
end

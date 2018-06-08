require 'rack'

module Frankie
  module BookKeeping
    VERSION = 0.4
  end

  class Application
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

      @response = {
        status:  200,
        headers: headers,
        body:    []
      }

      route!

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

    def route!
      match = Application.routes
                         .select { |route| route[:verb] == @verb }
                         .find   { |route| route[:pattern].match(@path) }
      return status(404) unless match

      values = match[:pattern].match(@path).captures
      params.merge!(match[:keys].zip(values).to_h)
      body instance_eval(&match[:block])
    end
  end

  module Delegator
    def self.delegate(method_name)
      define_method(method_name) do |*args, &block|
        Application.send(method_name, *args, &block)
      end
    end

    delegate(:get)
    delegate(:post)
    delegate(:use)
  end
end

extend Frankie::Delegator

use Rack::Session::Cookie, :key => 'rack.session', :secret => "secret"

get '/set_message' do
  session[:message] = "Hello, there."
  "Message has been set."
end

get '/get_message' do
  if session[:message]
    "Your message: " + session.delete(:message)
  else
    "There is no message."
  end
end

Rack::Handler::WEBrick.run Frankie::Application

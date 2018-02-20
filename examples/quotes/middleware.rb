class MyMiddleware
  def initialize(app)
    @app = app
  end

  # call comes from the handler
  def call(env)
    start = Time.now
    status, headers, body = @app.call(env) # call is forwarded to @app
    stop = Time.now
    puts "Response time: #{stop - start}"
    [status, headers, body] # response is forwarded to handler
  end
end

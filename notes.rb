# registering a route

# => on the class object

# the Rack interface

class < self
  def prototype
    @prototype ||= new
  end

  def call
    prototype.call(env)
  end
end

def call(env)
  dup.call!(env)
end

def call(env)
  dup.call!(env)
end

# request dispatch

def call!(env)
  @env      = env
  @request  = Request.new(env)
  @response = Response.new
  @params   = indifferent_params(@request.params)
  template_cache.clear if settings.reload_templates
  force_encoding(@params)

  @response['Content-Type'] = nil
  invoke { dispatch! } # HERE (why not just dispatch! ??)
  invoke { error_block!(response.status) } unless @env['sinatra.error']

  unless @response['Content-Type']
    if Array === body and body[0].respond_to? :content_type
      content_type body[0].content_type
    else
      content_type :html
    end
  end

  @response.finish
end

def invoke
  res = catch(:halt) { yield }
  res = [res] if Fixnum === res or String === res
  if Array === res and Fixnum === res.first
    res = res.dup
    status(res.shift)
    body(res.pop)
    headers(*res)
  elsif res.respond_to? :each
    body res
  end
  nil
end

def dispatch!
  invoke do # dispatch! calls invoke again. why is that?
    static! if settings.static? && (request.get? || request.head?)
    filter! :before
    route! # HERE
  end
rescue ::Exception => boom
  invoke { handle_exception!(boom) }
ensure
  begin
    filter! :after unless env['sinatra.static_file']
  rescue ::Exception => boom
    invoke { handle_exception!(boom) } unless @env['sinatra.error']
  end
end

# routing logic

def route!(base = settings, pass_block = nil)
  if routes = base.routes[@request.request_method]
    routes.each do |pattern, keys, conditions, block|
      returned_pass_block = process_route(pattern, keys, conditions) do |*args|
        env['sinatra.route'] = block.instance_variable_get(:@route_name)
        route_eval { block[*args] } # HERE
      end

      # don't wipe out pass_block in superclass
      pass_block = returned_pass_block if returned_pass_block
    end
  end

  # Run routes defined in superclass.
  if base.superclass.respond_to?(:routes)
    return route!(base.superclass, pass_block)
  end

  route_eval(&pass_block) if pass_block
  route_missing
end

def route_eval
  throw :halt, yield
end

# redirect

def redirect(uri, *args)
  if env['HTTP_VERSION'] == 'HTTP/1.1' and env["REQUEST_METHOD"] != 'GET'
    status 303
  else
    status 302
  end

  # According to RFC 2616 section 14.30, "the field value consists of a
  # single absolute URI"
  response['Location'] = uri(uri.to_s, settings.absolute_redirects?, settings.prefixed_redirects?)
  halt(*args)
end

def halt(*response)
  response = response.first if response.length == 1
  throw :halt, response
end

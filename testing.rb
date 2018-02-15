def call!
  invoke { dispatch! }
end

def invoke
  catch(:halt) { yield }
end

def dispatch!
  invoke do
    route!
  end
end

def route!
  for every route:
    if the route is a match, throw halt, instance_eval(&block)
end

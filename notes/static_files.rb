def static!(options = {})
  return if (public_dir = settings.public_folder).nil?
  path = File.expand_path("#{public_dir}#{URI_INSTANCE.unescape(request.path_info)}" )
  return unless File.file?(path)

  env['sinatra.static_file'] = path
  cache_control(*settings.static_cache_control) if settings.static_cache_control?
  send_file path, options.merge(:disposition => nil)
end

def send_file(path, opts = {})
  if opts[:type] or not response['Content-Type']
    content_type opts[:type] || File.extname(path), :default => 'application/octet-stream'
  end

  disposition = opts[:disposition]
  filename    = opts[:filename]
  disposition = 'attachment' if disposition.nil? and filename
  filename    = path         if filename.nil?
  attachment(filename, disposition) if disposition

  last_modified opts[:last_modified] if opts[:last_modified]

  file      = Rack::File.new nil
  file.path = path
  result    = file.serving env
  result[1].each { |k,v| headers[k] ||= v }
  headers['Content-Length'] = result[1]['Content-Length']
  opts[:status] &&= Integer(opts[:status])
  halt opts[:status] || result[0], result[2]
rescue Errno::ENOENT
  not_found
end

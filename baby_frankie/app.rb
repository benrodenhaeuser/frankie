# app.rb

require_relative 'baby_frankie'

Baby::App.get('/') { 'hello world' }

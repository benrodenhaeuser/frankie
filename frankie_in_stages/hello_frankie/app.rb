# app.rb

require_relative 'frankie'

Frankie::App.get('/') { 'hello world' }

# app.rb

require_relative 'baby_frankie'

BabyFrankie::Application.get('/') { 'hello world' }

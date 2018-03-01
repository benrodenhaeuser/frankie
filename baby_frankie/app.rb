# app.rb

require_relative 'baby_frankie'

BabyFrankie::Application.route('GET', '/') { 'hello world' }

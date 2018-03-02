# app.rb

require_relative 'frankie'

Frankie::App.get('/') { 'frankie says hello.' }

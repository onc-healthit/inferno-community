#\ -s Thin -p 4567

#require 'rubygems'
#require 'sinatra'
#require File.expand_path '../app.rb', __FILE__
#run Sinatra::Application

require './lib/app'
run Inferno::App.new

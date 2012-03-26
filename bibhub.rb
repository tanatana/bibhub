require 'rubygems'
require 'sinatra'

configure do
  set :logging, true
  set :dump_errors, true
  set :show_exceptions, true
end

get '/' do
  "bibhub"
end

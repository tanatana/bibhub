require 'rubygems'
require 'sinatra/base'

class BibhubApp < Sinatra::Base
  configure do
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end
  
  get '/' do
    "bibtex"
  end
end

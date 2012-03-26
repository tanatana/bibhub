require 'rubygems'
require 'sinatra/base'
require 'omniauth'
require 'erb'

class BibhubApp < Sinatra::Base

  configure do
    use Rack::Session::Cookie, :secret => "change me"
    
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end
  
  use OmniAuth::Builder do
    provider :twitter,'P2ZQaY38pGcxwMgShg3rXQ','aUKFW4xzx2tJEkK1dxnsZZCqJhQzhFV8uHUTGxjUc'
  end

  get '/' do
    erb :index
  end

  get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    erb :index2
  end
  
end

$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'sinatra/base'
require 'omniauth-twitter'
require 'erb'
require 'mongo_mapper'
require 'models/user'

class BibhubApp < Sinatra::Base

  MongoMapper.database = "bibhub"
  
  configure do
    use Rack::Session::Cookie, :secret => "change me"
    
    set :logging, true
    set :dump_errors, true
    set :show_exceptions, true
  end
  
  use OmniAuth::Builder do
    provider :twitter,'P2ZQaY38pGcxwMgShg3rXQ','aUKFW4xzx2tJEkK1dxnsZZCqJhQzhFV8uHUTGxjUc'
  end

  def get_user
    @user ||= User.find_by_user_id(session[:user_id])
  end

  get '/' do
    erb :index
  end

  get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    session[:user_id] = @auth['uid']

    @user = User.find_or_initialize_by_user_id(@auth['uid'])
    @user.token = @auth['credentials']['token']
    @user.secret = @auth['credentials']['secret']

    @user.save

    erb :index2
  end
end

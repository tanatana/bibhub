# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'sinatra/base'
require 'omniauth-twitter'
require 'erb'
require 'mongo_mapper'
require 'models/user'
require 'models/bibtex'
require 'open-uri'
require 'bibtex'
require 'kconv'

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
  
  get '/bibtex/url' do
    erb :url
  end

  post '/bibtex/url' do
    return "" unless params.key? "bibtex"
    bib = BibTeX.parse params["bibtex"][:tempfile].read.toutf8
    Bibtex::create(bib.to_hash)
    bib.to_json
  end
end

# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'sinatra/base'
require 'omniauth-twitter'
require 'erb'
require 'mongo_mapper'
require 'models/user'
require 'models/bibliography'
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
    if get_user
      erb :index
    else
      erb :login
    end
  end

  get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    session[:user_id] = @auth['uid']

    @user = User.find_or_initialize_by_user_id(@auth['uid'])
    @user.token = @auth['credentials']['token']
    @user.secret = @auth['credentials']['secret']
    @user.save

    erb :index
  end
  
  get '/logout' do
    session.delete(:user_id)
    redirect '/'
  end

  get '/user/:user_id' do
    "hello"
  end

  get '/user/:user_id/:bibtex_id' do
    "bibtex"
  end

  get '/user/:user_id/search' do
    "search"
  end

  get '/user/:user_id/:tag' do
    "tag"
  end

  get '/api/:user_id' do
    params[:user_id]
  end

  get '/api/:user_id/:bibtex_id' do
    "bibtex"
  end

  get '/api/:user_id/search' do
    "search"
  end

  get '/api/:user_id/:tag' do
    "tag"
  end

  

  get '/bibtex/url' do
    @title = "BibTeXをアップロード"
    erb :url
  end

  post '/bibtex/url' do
    return "" unless params.key? "bibtex"

    bibtex = BibTeX.parse params["bibtex"][:tempfile].read.toutf8
    bibtex.each{|e|
      bib = Bibliography::create(e.to_hash)
      bib.creator = get_user
      bib.updater = get_user
      bib.save
    }

    bibtex.to_json
  end
end

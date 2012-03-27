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
require 'json'

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

  helpers do
    def login?
      return @user if @user
      return unless session[:user_id]
      @user = User.find_by_user_id session[:user_id]
      return unless @user
      @user
    end
  end

  get '/' do
    if login?
      erb :index
    else
      redirect 'login'
    end
  end

  get '/auth/:name/callback' do
    pp @auth = request.env['omniauth.auth']
    session[:user_id] = @auth['uid']

    @user = User.find_or_initialize_by_user_id(@auth['uid'])
    @user.token = @auth['credentials']['token']
    @user.secret = @auth['credentials']['secret']
    @user.screen_name = @auth['info']['nickname']
    @user.save

    erb :index
  end

  get '/login' do
    erb :login
  end

  get '/logout' do
    session.delete(:user_id)
    redirect '/'
  end

  get '/bibtex/url' do
    redirect '/login' unless login?
    @title = "BibTeXをアップロード"
    erb :url
  end

  post '/bibtex/url' do
    return "" unless login?
    return "" unless params.key? "bibtex"

    bibtex = BibTeX.parse params["bibtex"][:tempfile].read.toutf8
    bibtex.each{|e|
      bib = Bibliography::create(e.to_hash)
      bib.creator = @user
      bib.updater = @user
      bib.save
    }

    redirect '/'
  end

  get '/user/:screen_name' do
    @title = "ユーザー情報"
    @user = Bibliography.find_by_screen_name params[:screen_name]
    erb :user
  end

  get '/bibtex/:bibtex_id' do
    @title = "BibTeX情報"
    @bibtex = Bibliography.find_by_id params[:bibtex_id]
    erb :bibtex
  end

  get '/search' do
    "search"
  end

  get '/api/user/:user_id' do
    user = User.find_by_user_id params[:user_id]
    content_type :json
    user.to_json
  end

  get '/api/bibtex/:bibtex_id' do
    bib = Bibliography.find_by_id params[:bibtex_id]
    bib.to_json
  end

  get '/api/search' do
    "search"
  end
end

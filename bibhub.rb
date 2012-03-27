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
      @title = "ようこそ #{@user.screen_name} さん!"
      @bibtex = Bibliography.where({creator_id:@user.id})
        .limit(20).map{|e| e.to_bibtex}
      erb :index
    else
      redirect 'login'
    end
  end

  get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    session[:user_id] = @auth['uid']

    @user = User.find_or_initialize_by_user_id(@auth['uid'])
    @user.token = @auth['credentials']['token']
    @user.secret = @auth['credentials']['secret']
    @user.screen_name = @auth['info']['nickname']
    @user.save

    redirect '/'
  end

  get '/auth/failure' do
    "login failed: #{params[:message]}"
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
      data = Bibliography::create(:bibtex => e.to_hash)
      data.creator = @user
      data.updater = @user
      data.save
    }

    redirect '/'
  end

  get '/user/:screen_name' do
    @user = User.find_by_screen_name params[:screen_name]
    @title = "#{@user.screen_name}"

    erb :user
  end

  get '/bibtex/:bibtex_id' do
    @bibtex = Bibliography.find_by_id(params[:bibtex_id]).to_bibtex
    @title = "#{@bibtex[:bibtex].title.to_s(:filter => :latex)}"

    erb :bibtex
  end

  get '/search' do
    "search"
  end

  get '/api/user/recent' do
    return unless login?
    @user.id
    content_type :json
    Bibliography.where(:creator_id => @user.id).limit(20).to_json
  end

  get '/api/user/id/:user_id' do
    user = User.find_by_user_id params[:user_id]
    content_type :json
    user.to_json
  end

  get '/api/bibtex/:bibtex_id' do
    bib = Bibliography.find_by_id(params[:bibtex_id])
    bib.to_json
  end

  get '/api/search' do

    content_type :json

    bibs = Bibliography.all(:creator_id => "4f71531a1d78912541000001")
    bibs_json = ""

    bibs.each do |bib|
      bibs_json << bib.to_json
    end
    bibs_json
  end
end

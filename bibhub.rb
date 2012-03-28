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

    def export_button(user, bibtex)
      @user = user
      @bibtex = bibtex
      erb :export_button, :layout => false;
    end
  end

  get '/' do
    @comments = []
    @bibtex = []

    if login?
      @title = "ようこそ #{@user.screen_name} さん!"
      @bibtex = Bibliography.where({creator_id:@user.id}).map{|e| e.to_bibtex}
      @comments = Comment.where({creator_id:@user.id}).limit(20).sort(:created_at.desc)
    end

    erb :index
  end

  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:user_id] = auth['uid']

    user = User.find_or_initialize_by_user_id(auth['uid'])
    user.token = auth['credentials']['token']
    user.secret = auth['credentials']['secret']
    user.screen_name = auth['info']['nickname']
    user.save

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
      hash = e.to_hash
      bib = Bibliography.where("bibtex.title".to_sym => hash[:title]).first
      unless bib
        bib = Bibliography.new(:bibtex => e.to_hash)
        bib.creator = @user
      end
      bib.updater = @user
      bib.bibtex = hash
      bib.save
    }

    redirect '/'
  end

  get '/user/:screen_name' do
    @user = User.find_by_screen_name params[:screen_name]
    @title = "#{@user.screen_name}"

    erb :user
  end

  get '/bibtex/:bibtex_id' do
    @user = login?
    @bibtex = Bibliography.find_by_id(params[:bibtex_id]).to_bibtex
    @title = "#{@bibtex.title}"
    @author = @bibtex.author.split(/\s+and\s+/)

    erb :bibtex
  end

  get '/search' do
    "search"
  end

  get '/api/user/recent' do
    return unless login?
    content_type :json
    Bibliography.where(:creator_id => @user.id).limit(20).to_json
  end

  get '/api/user/id/:user_id' do
    content_type :json
    user = User.find_by_user_id params[:user_id]
    user.to_json
  end

  get '/api/bibtex/*.bib' do
    return "error" if params[:splat].size < 1

    content_type "text/x-bibtex"
    bib = Bibliography.find_by_id(params[:splat][0])
    BibTeX::Bibliography.new.add(BibTeX::Entry.new(bib.bibtex.symbolize_keys)).to_s(:quotes => [])
  end

  get '/api/search' do
    content_type :json
    Bibliography.all('bibtex.title'.to_sym => /#{@params[:word]}/i).map{|e| e.to_bibtex}.to_json
  end

  post '/api/bibtex/add_comment' do
    @user = User.find_by_user_id session[:user_id]

    @bibtex = Bibliography.find_by_id(params[:bibtex_id])
    comment = Comment.create({:creator => @user, :comment => params[:comment], :bibliographys_id => params[:bibtex_id]})
    @bibtex.comments << comment
    @bibtex.save

    redirect "/bibtex/#{params[:bibtex_id]}"
  end

  post '/api/user/export/add' do
    return "error" unless login?
    bib = Bibliography.find_by_id(params[:bibtex_id])
    @user.exports << bib
    @user.save

    JSON.unparse({
        result: true,
        html: export_button(@user, bib)
      })
  end

  post '/api/user/export/remove' do
    return "error" unless login?
    bib = @user.exports.find_by_id(params[:bibtex_id])
    return "error" unless bib
    @user.exports = @user.exports.delete_if{|e| e.id == bib.id}
    @user.save

    JSON.unparse({
        result: true,
        html: export_button(@user, bib)
      })
  end
end

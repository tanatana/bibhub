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

    include ERB::Util
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
      erb :export_button, :layout => false
    end

    def comment_tag(comment)
      @comment = comment
      erb :comment_tag, :layout => false
    end
  end

  get '/' do
    @comments = []
    @bibtex = []

    if login?
      @title = "ようこそ #{@user.screen_name} さん!"
      @bibtex = Bibliography.where({creator_id:@user.id}).sort(:created_at.desc).map{|e| e.to_bibtex}

      @comments = Comment.where({creator_id:@user.id}).limit(20).sort(:created_at.desc)
      erb :index
    else
      @title = "Twitterでログイン!"
      erb :login
    end
  end

  get '/bibtex/recent' do
    @title = "最近追加された論文"
    @bibtex = Bibliography.where.sort(:created_at.desc).map{|e| e.to_bibtex}
    erb :index
  end

  get '/comments/recent' do
    @comments = Comment.where.sort(:created_at.desc).limit(20)
    erb :recent_comments
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

  get '/logout' do
    session.delete(:user_id)
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

  get '/api/user/id/:user_id' do
    content_type :json
    user = User.find_by_user_id params[:user_id]
    user.to_json
  end

  post '/api/user/export/add' do
    content_type :json
    return JSON.unparse({result: false}) unless login?
    bib = Bibliography.find_by_id(params[:bibtex_id])

    return JSON.unparse({result: false}) unless bib
    @user.exports << bib
    @user.save

    JSON.unparse({
        result: true,
        html: export_button(@user, bib)
      })
  end

  post '/api/user/export/remove' do
    content_type :json

    return JSON.unparse({result: false}) unless login?
    bib = @user.exports.find_by_id(params[:bibtex_id])
    return JSON.unparse({result: false}) unless bib

    @user.exports = @user.exports.delete_if{|e| e.id == bib.id}
    @user.save

    JSON.unparse({
        result: true,
        html: export_button(@user, bib)
      })
  end

  post '/api/bibtex/upload' do
    content_type :json
    if not login? or not params.key? "bibtex"
      return JSON.unparse({
          result: false
        })
    end

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

    bibtex.to_json
  end

  get '/api/bibtex/*.bib' do
    return "error" if params[:splat].size < 1

    content_type "text/x-bibtex"
    bib = Bibliography.find_by_id(params[:splat][0])
    BibTeX::Bibliography.new.add(BibTeX::Entry.new(bib.bibtex.symbolize_keys)).to_s(:quotes => [])
  end

  post '/api/bibtex/comment/add' do
    @user = User.find_by_user_id session[:user_id]
    @bibtex = Bibliography.find_by_id(params[:bibtex_id])

    content_type :json
    return JSON.unparse({result: false}) if not @user or not @bibtex

    comment = Comment.create({:creator => @user, :comment => params[:comment], :bibliographys_id => params[:bibtex_id]})
    @bibtex.comments << comment
    @bibtex.save

    JSON.unparse({result: true, html: comment_tag(comment)})
  end

  get '/api/search' do
    content_type :json
    Bibliography.all('bibtex.title'.to_sym => /#{@params[:word]}/i).map{|e| e.to_bibtex}.to_json
  end
end

$:.unshift File.dirname(__FILE__)
require 'bibtex'
require 'comment'


class Bibliography
  include MongoMapper::Document

  timestamps!
  userstamps!

  many :comments

  def to_bibtex
    BibTeX::Entry.new(self[:bibtex]).reduce(self){|r, e|
      r[e[0]] = e[1].to_s(:filter => :latex)
      r
    }
  end
end

require 'bibtex'

class Bibliography
  include MongoMapper::Document

  timestamps!
  userstamps!

  def to_bibtex
    BibTeX::Entry.new(self[:bibtex]).reduce(self){|r, e|
      r[e[0]] = e[1].to_s(:filter => :latex)
      r
    }
  end
end

require 'bibtex'

class Bibliography
  include MongoMapper::Document

  timestamps!
  userstamps!

  def to_bibtex
    self[:bibtex] = BibTeX::Entry.new(self[:bibtex])
    self
  end
end

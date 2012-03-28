class Comment
  include MongoMapper::Document
  belongs_to :bibliographys
  
  key :comment, String

  timestamps!
  userstamps!
end

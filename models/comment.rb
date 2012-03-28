class Comment
  include MongoMapper::EmbeddedDocument
  
  key :creator, User
  key :comment, String

  timestamps!
end

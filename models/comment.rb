class Comment
  include MongoMapper::Document
  belongs_to :bibliography

  key :comment, String

  timestamps!
  userstamps!
end

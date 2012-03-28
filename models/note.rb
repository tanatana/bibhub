class Note
  indlude MongoMapper::EmbeddedDocument

  key :user, User
  key :note, String

  timestamps!
  userstamps!
end

class User
  include MongoMapper::Document
  key :user_id, String, :required => true 
  key :token, String
  key :secret,String

  timestamps!
end

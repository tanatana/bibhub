class User
  include MongoMapper::Document
  key :user_id, String, :required => true
  key :token, String
  key :secret, String
  key :screen_name, String

  key :export_ids, Set
  many :exports, :class_name => 'Bibliography', :in => :export_ids

  timestamps!
end

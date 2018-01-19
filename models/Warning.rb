class Warning
  include DataMapper::Resource
  property :id, Serial
  property :message, String, length: 500

  belongs_to :test_result
end

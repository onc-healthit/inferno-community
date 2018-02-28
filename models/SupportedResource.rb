class SupportedResource
  include DataMapper::Resource
  property :id, String, key: true, default: proc { SecureRandom.uuid}
  property :resource_type, String
  property :read_supported, Boolean, default: false
  property :vread_supported, Boolean, default: false
  property :history_supported, Boolean, default: false
  property :scope_supported, Boolean, default: false

  belongs_to :testing_instance
end

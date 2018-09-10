#DataMapper::Logger.new($stdout, :debug) if settings.environment == :development
DataMapper::Model.raise_on_save_failure = true

DataMapper.setup(:default, "sqlite3:data/dev_data.db")

require_relative 'models/request_response'
require_relative 'models/resource_reference'
require_relative 'models/sequence_result'
require_relative 'models/supported_resource'
require_relative 'models/test_result'
require_relative 'models/test_warning'
require_relative 'models/testing_instance'

DataMapper.finalize

#[Inferno::Models::TestingInstance,
# Inferno::Models::SequenceResult,
# Inferno::Models::TestResult,
# Inferno::Models::TestWarning,
# Inferno::Models::RequestResponse,
# Inferno::Models::RequestResponse,
# Inferno::Models::TestResult,
# Inferno::Models::SupportedResource,
# Inferno::Models::ResourceReference].each(&:auto_upgrade!)
# Inferno::Models::ResourceReference].each(&:auto_upgrade!)

DataMapper.auto_upgrade!
class SequenceResult
  include DataMapper::Resource
  property :id, String, key: true
  property :name, String
  property :result, String #pass fail
  property :passed_count, Integer
  property :failed_count, Integer
  property :warning_count, Integer

  has n, :test_results
  belongs_to :testing_instance
end

class SequenceResult
  include DataMapper::Resource
  property :id, Serial
  property :result, String #pass fail skip
  property :passed_count, Integer
  property :failed_count, Integer

  has n, :test_results
  belongs_to :testing_instance
end


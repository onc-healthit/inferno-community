class TestResult
  include DataMapper::Resource
  property :id, Serial
  property :result, String #pass fail skip

  belongs_to :sequence_result
end

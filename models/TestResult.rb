class TestResult
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :result, String #pass fail

  belongs_to :sequence_result
end

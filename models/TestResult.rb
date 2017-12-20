class TestResult
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :result, String #pass fail skip

  belongs_to :sequence_result
end

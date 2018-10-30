require File.expand_path '../../test_helper.rb', __FILE__

class SecureRandomTest < MiniTest::Test

  def setup
    @random_64_bit = Array.new(1000){Inferno::SecureRandomBase62.generate(64)}
    @random_32_bit = Array.new(1000){Inferno::SecureRandomBase62.generate(32)}
  end


  def test_secure_random_no_repeats
    assert @random_64_bit.uniq.length == @random_64_bit.length
  end

  def test_secure_random_length
    # unlikely
    assert @random_64_bit.select{|e| e.length < 9}.length < 100
    assert @random_32_bit.select{|e| e.length < 4}.length < 100
  end

end

require 'base62-rb'

module Inferno
  class SecureRandomBase62

    BITS_ENTROPY = 64

    def self.generate(entropy = BITS_ENTROPY)

      Base62.encode SecureRandom.random_number(2**entropy)

    end

  end
end
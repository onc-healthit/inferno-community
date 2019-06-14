# frozen_string_literal: true

module Inferno
  module ResultStatuses
    def fail?
      result == 'fail' || error?
    end

    def error?
      result == 'error'
    end

    def pass?
      result == 'pass'
    end

    def skip?
      result == 'skip'
    end

    def wait?
      result == 'wait'
    end

    def fail!
      self.result = 'fail'
    end

    def error!
      self.result = 'error'
    end

    def pass!
      self.result = 'pass'
    end

    def skip!
      self.result = 'skip'
    end

    def wait!
      self.result = 'wait'
    end

    def todo!
      self.result = 'todo'
    end
  end
end

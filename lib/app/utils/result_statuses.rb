# frozen_string_literal: true

module Inferno
  module ResultStatuses
    FAIL = 'fail'
    ERROR = 'error'
    PASS = 'pass'
    SKIP = 'skip'
    WAIT = 'wait'
    TODO = 'todo'

    STATUS_LIST = [FAIL, ERROR, PASS, SKIP, WAIT, TODO].freeze

    def fail?
      result == FAIL || error?
    end

    def error?
      result == ERROR
    end

    def pass?
      result == PASS
    end

    def skip?
      result == SKIP
    end

    def wait?
      result == WAIT
    end

    def todo?
      result == TODO
    end

    def fail!
      self.result = FAIL
    end

    def error!
      self.result = ERROR
    end

    def pass!
      self.result = PASS
    end

    def skip!
      self.result = SKIP
    end

    def wait!
      self.result = WAIT
    end

    def todo!
      self.result = TODO
    end
  end
end

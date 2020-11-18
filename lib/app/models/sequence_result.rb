# frozen_string_literal: true

require_relative '../utils/result_statuses'
require_relative '../utils/logging'

module Inferno
  class SequenceResult < ApplicationRecord
    include ResultStatuses

    attribute :id, :string, default: -> { SecureRandom.uuid }
    attribute :required, :boolean, default: true
    attribute :created_at, :datetime, default: -> { DateTime.now }
    attribute :test_case_id, :string
    attribute :test_set_id, :string

    has_many :test_results, -> { order 'test_index ASC' }
    belongs_to :testing_instance

    def self.recent_results_for_iss(iss)
      where(result: 'wait')
        .where('created_at >= ?', 5.minutes.ago)
        .order(created_at: :desc)
        .find { |result| normalize_url(result.testing_instance.url) == normalize_url(iss) }
    end

    def failures
      test_results.select(&:fail?)
    end

    def reset!
      [
        'required_passed',
        'required_total',
        'error_count',
        'todo_count',
        'skip_count',
        'optional_passed',
        'optional_total',
        'required_omitted',
        'optional_omitted'
      ].each { |field| send("#{field}=", 0) }
    end

    def result_count
      test_results.length
    end

    def total_omitted
      required_omitted + optional_omitted
    end

    def total_required_tests_except_omitted
      required_total - required_omitted
    end

    def update_result_counts
      test_results.each do |result|
        if result.required
          self.required_total += 1
        else
          self.optional_total += 1
        end
        case result.result
        when ResultStatuses::PASS
          if result.required
            self.required_passed += 1
          else
            self.optional_passed += 1
          end
          self.result = result.result unless error? || fail? || skip?
        when ResultStatuses::OMIT
          if result.required
            self.required_omitted += 1
          else
            self.optional_omitted += 1
          end
        when ResultStatuses::TODO
          self.todo_count += 1
        when ResultStatuses::FAIL
          if result.required
            self.result = result.result unless error?
          end
        when ResultStatuses::ERROR
          if result.required
            self.error_count += 1
            self.result = result.result
          end
        when ResultStatuses::SKIP
          if result.required
            self.result = result.result if pass? || self.result.nil?
            self.skip_count += 1
          end
        when ResultStatuses::WAIT
          self.result = result.result
        end
      end
      self.result = ResultStatuses::PASS if self.result.nil?
    end

    def self.normalize_url(url)
      url&.downcase&.split('://')&.last&.chomp('/')
    end
    private_class_method :normalize_url
  end
end

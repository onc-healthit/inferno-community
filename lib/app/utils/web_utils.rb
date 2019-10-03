# frozen_string_literal: true

module Inferno
  module WebUtils
    def self.get_with_retry(url, timeout, fhir_client)
      wait_time = 1
      reply = nil
      start = Time.now
      seconds_used = 0

      loop do
        reply = nil
        begin
          reply = fhir_client.client.get(url)
        rescue RestClient::TooManyRequests => e
          reply = e.response
        end
        wait_time = get_retry_or_backoff_time(wait_time, reply)
        seconds_used = Time.now - start
        # exit loop if we get a successful response or timeout reached
        break if (reply.code >= 200 && reply.code < 300) || (seconds_used > timeout)

        sleep wait_time
      end

      reply
    end

    def self.get_retry_or_backoff_time(wait_time, reply)
      retry_after = -1
      unless reply.headers.nil?
        reply.headers.symbolize_keys
        retry_after = reply.headers[:retry_after].to_i || -1
      end

      if retry_after.positive?
        retry_after
      else
        wait_time * 2
      end
    end
  end
end

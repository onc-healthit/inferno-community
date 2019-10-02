# frozen_string_literal: true

module Inferno
  module WebUtils
    def get_with_retry(url, timeout)
      wait_time = 1
      reply = nil
      start = Time.now

      loop do
        reply = @client.get(url)

        wait_time = get_retry_or_backoff_time(wait_time, reply)
        seconds_used = Time.now - start + wait_time

        break if reply.code != 202 || seconds_used > timeout

        sleep wait_time
      end

      reply
    end

    def get_retry_or_backoff_time(wait_time, reply)
      retry_after = reply.response[:headers]['retry-after']
      retry_after_int = (retry_after.presence || 0).to_i

      if retry_after_int.positive?
        retry_after_int
      else
        wait_time * 2
      end
    end
  end
end

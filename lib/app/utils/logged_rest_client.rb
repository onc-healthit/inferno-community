# frozen_string_literal: true

module Inferno
  class LoggedRestClient
    @@requests = []

    def self.clear_log
      @@requests = []
    end

    def self.requests
      @@requests
    end

    def self.record_response(request, response)
      # You can call this directly with a hash
      # If intercepted from RestClient it will use a class
      reply = if response.instance_of? Hash
                {
                  code: response[:code],
                  headers: response[:headers],
                  body: response[:body]
                }
              else
                {
                  code: response.code,
                  headers: response.headers,
                  body: response.body
                }
              end

      reply[:timestamp] = DateTime.now

      request[:payload] = begin
                            JSON.parse(request[:payload])
                          rescue StandardError
                            request[:payload]
                          end
      @@requests << { direction: :outbound, request: request, response: reply }
    end

    def post(url, payload, headers = {})
      reply = RestClient.post(url, payload, headers)
      request = {
        method: :post,
        url: url,
        headers: headers,
        payload: payload
      }

      # request[:payload] = URI.encode_www_form(payload) if payload.is_a?(Hash)
      request[:payload] = payload.to_json if payload.is_a?(Hash)
      record_response(request, reply)
      reply
    end

    def self.get(url, headers = {}, &block)
      begin
        reply = RestClient.get(url, headers, &block)
      rescue StandardError => e
        if !e.respond_to?(:response) || e.response.nil?
          # Re-raise the client error if there's no response.
          raise # Re-raise the same error we caught.
        end

        reply = e.response if e.response
      end

      request = {
        method: :get,
        url: url,
        headers: headers
      }
      record_response(request, reply)
      reply
    end

    def self.post(url, payload, headers = {}, &block)
      begin
        reply = RestClient.post(url, payload, headers, &block)
      rescue StandardError => e
        if !e.respond_to?(:response) || e.response.nil?
          # Re-raise the client error if there's no response.
          raise # Re-raise the same error we caught.
        end

        reply = e.response if e.response
      end

      request = {
        method: :post,
        url: url,
        headers: headers,
        payload: payload
      }

      # request[:payload] = URI.encode_www_form(payload) if payload.is_a?(Hash)
      request[:payload] = payload.to_json if payload.is_a?(Hash)
      record_response(request, reply)
      reply
    end

    def self.patch(url, payload, headers = {}, &block)
      reply = RestClient.patch(url, payload, headers, &block)
      request = {
        method: :patch,
        url: url,
        headers: headers,
        payload: payload
      }

      # request[:payload] = URI.encode_www_form(payload) if payload.is_a?(Hash)
      request[:payload] = payload.to_json if payload.is_a?(Hash)
      record_response(request, reply)
      reply
    end

    def self.put(url, payload, headers = {}, &block)
      reply = RestClient.put(url, payload, headers, &block)
      request = {
        method: :put,
        url: url,
        headers: headers,
        payload: payload
      }

      # request[:payload] = URI.encode_www_form(payload) if payload.is_a?(Hash)
      request[:payload] = payload.to_json if payload.is_a?(Hash)
      record_response(request, reply)
      reply
    end

    def self.delete(url, headers = {}, &block)
      reply = RestClient.delete(url, headers, &block)
      request = {
        method: :delete,
        url: url,
        headers: headers
      }
      record_response(request, reply)
      reply
    end

    def self.head(url, headers = {}, &block)
      reply = RestClient.delete(url, headers, &block)
      request = {
        method: :delete,
        url: url,
        headers: headers
      }
      record_response(request, reply)
      reply
    end

    def self.options(url, headers = {}, &block)
      reply = RestClient.options(url, headers, &block)
      request = {
        method: :options,
        url: url,
        headers: headers
      }
      record_response(request, reply)
      reply
    end
  end
end

class LoggedRestClient

  @@requests = []

  def self.clear_log
    @@requests = []
  end

  def self.requests
    @@requests
  end

  def self.record_response(request, response)
    reply = {
      code: response.code,
      headers: response.headers,
      body: response.body
    }
    request[:payload] = JSON.parse(request[:payload]) rescue nil
    @@requests << {direction: :outbound, request: request, response: reply}
  end

  def post(url, payload, headers = {})
    reply = RestClient.post(url, payload, headers)
    request = {
      method: :post,
      url: url,
      headers: headers,
      payload: payload.to_json
    }
    self.record_response(request, reply)
    return reply
  end

  def self.get(url, headers={}, &block)
    begin
      reply = RestClient.get(url, headers, &block)
    rescue => e
      unless e.response
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
    self.record_response(request, reply)
    return reply
  end

  def self.post(url, payload, headers={}, &block)
    begin
      reply = RestClient.post(url, payload, headers, &block)
    rescue => e
      unless e.response
        # Re-raise the client error if there's no response.
        raise # Re-raise the same error we caught.
      end
      reply = e.response if e.response
    end

    request = {
      method: :post,
      url: url,
      headers: headers,
      payload: payload.to_json
    }
    self.record_response(request, reply)
    return reply
  end

  def self.patch(url, payload, headers={}, &block)
    reply = RestClient.patch(url, payload, headers, &block)
    request = {
      method: :patch,
      url: url,
      headers: headers,
      payload: payload
    }
    self.record_response(request, reply)
    return reply
  end

  def self.put(url, payload, headers={}, &block)
    reply = RestClient.put(url, payload, headers, &block)
    request = {
      method: :put,
      url: url,
      headers: headers,
      payload: payload
    }
    self.record_response(request, reply)
    return reply
  end

  def self.delete(url, headers={}, &block)
    reply = RestClient.delete(url, headers, &block)
    request = {
      method: :delete,
      url: url,
      headers: headers
    }
    self.record_response(request, reply)
    return reply
  end

  def self.head(url, headers={}, &block)
    reply = RestClient.delete(url, headers, &block)
    request = {
      method: :delete,
      url: url,
      headers: headers
    }
    self.record_response(request, reply)
    return reply
  end

  def self.options(url, headers={}, &block)
    reply = RestClient.options(url, headers, &block)
    request = {
      method: :options,
      url: url,
      headers: headers
    }
    self.record_response(request, reply)
    return reply
  end

end

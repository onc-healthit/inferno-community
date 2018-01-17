require_relative 'assertions'

module Assertions

  def assert(test, message="assertion failed, no message", data="")
    unless test
      raise AssertionException.new message, data
    end
  end

  def assert_equal(expected, actual, message="", data="")
    unless assertion_negated( expected == actual )
      message += " Expected: #{expected}, but found: #{actual}."
      raise AssertionException.new message, data
    end
  end

  def assert_operator(operator, expected, actual, message="", data="")
    case operator
    when :equals
      unless assertion_negated( expected == actual )
        message += " Expected #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :notEquals
      unless assertion_negated( expected != actual )
        message += " Did not expect #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :in
      unless assertion_negated(expected.split(",").include?(actual))
        message += " Expected #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :notIn
      unless assertion_negated(!expected.split(",").include?(actual))
        message += " Did not expect #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :greaterThan
      unless assertion_negated(!actual.nil? && !expected.nil? && actual > expected)
        message += " Expected greater than #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :lessThan
      unless assertion_negated(!actual.nil? && !expected.nil? && actual < expected)
        message += " Expected less than #{expected} but found #{actual}."
        raise AssertionException.new message, data
      end
    when :empty
      unless assertion_negated(actual.nil? || actual.length == 0)
        message += " Expected empty but found #{actual}."
        raise AssertionException.new message, data
      end
    when :notEmpty
      unless assertion_negated(!actual.nil? && actual.length > 0)
        message += " Expected not empty but found #{actual}."
        raise AssertionException.new message, data
      end
    when :contains
      unless assertion_negated(actual && actual.include?(expected))
        message += " Expected #{actual} to contain #{expected}."
        raise AssertionException.new message, data
      end
    when :notContains
      unless assertion_negated(actual.nil? || !actual.include?(expected))
        message += " Expected #{actual} to not contain #{expected}."
        raise AssertionException.new message, data
      end
    else
      message += " Invalid test; unknown operator: #{operator}."
      raise AssertionExection.new message, data
    end

  end

  def assert_valid_profile(response, klass)
    unless assertion_negated( response[:code].to_s == "200")

      raise AssertionException.new "Server created a #{klass.name.demodulize} with the ID `_validate` rather than validate the resource." if response[:code].to_s == "201"

      raise AssertionException.new "Response code #{response[:code]} with no OperationOutcome provided"
    end

  end

  def assert_response_ok(response, error_message="")
    unless assertion_negated( [200, 201].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 200, 201, but found #{response.code}.#{" " + error_message}", response.body
    end
  end

  def assert_response_created(response, error_message="")
    unless assertion_negated( [201].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 201, but found #{response.code}.#{" " + error_message}", response.body
    end
  end

  def assert_response_gone(response)
    unless assertion_negated( [410].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 410, but found #{response.code}", response.body
    end
  end

  def assert_response_not_found(response)
    unless assertion_negated( [404].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 404, but found #{response.code}", response.body
    end
  end

  def assert_response_bad(response)
    unless assertion_negated( [400].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 400, but found #{response.code}", response.body
    end
  end

  def assert_response_conflict(response)
    unless assertion_negated( [409, 412].include?(response.code) )
      raise AssertionException.new "Bad response code: expected 409 or 412, but found #{response.code}", response.body
    end
  end

  def assert_navigation_links(bundle)
    unless assertion_negated( bundle.first_link && bundle.last_link && bundle.next_link )
      raise AssertionException.new "Expecting first, next and last link to be present"
    end
  end

  def assert_bundle_response(response)
    unless assertion_negated( response.resource.class == get_resource(:Bundle) )
      # check what this is...
      found = response.resource
      begin
        found = resource_from_contents(response.body)
      rescue
        found = nil
      end
      raise AssertionException.new "Expected FHIR Bundle but found: #{found.class.name.demodulize}", response.body
    end
  end

  def assert_bundle_entry_count(response, count)
    unless assertion_negated( response.resource.total == count.to_i )
      raise AssertionException.new "Expected FHIR Bundle with #{count} entries but found: #{response.resource.total} entries", response.body
    end
  end

  def assert_bundle_transactions_okay(response)
    response.resource.entry.each do |entry|
      unless assertion_negated( !entry.response.nil? )
        raise AssertionException.new "All Transaction/Batch Bundle.entry elements SHALL have a response."
      end
      status = entry.response.status
      unless assertion_negated( status && status.start_with?('200','201','204') )
        raise AssertionException.new "Expected all Bundle.entry.response.status to be 200, 201, or 204; but found: #{status}"
      end
    end
  end

  def assert_resource_content_type(client_reply, content_type)
    header = client_reply.response[:headers]['content-type']
    response_content_type = header
    response_content_type = header[0, header.index(';')] if !header.index(';').nil?

    unless assertion_negated( "application/fhir+#{content_type}" == response_content_type )
      raise AssertionException.new "Expected content-type application/fhir+#{content_type} but found #{response_content_type}", response_content_type
    end
  end

  # Based on MIME Types defined in
  # http://hl7.org/fhir/2015May/http.html#2.1.0.6
  def assert_valid_resource_content_type_present(client_reply)
    header = client_reply.response[:headers]['content-type']
    content_type = header
    charset = encoding = nil

    content_type = header[0, header.index(';')] if !header.index(';').nil?
    charset = header[header.index('charset=')+8..-1] if !header.index('charset=').nil?
    encoding = Encoding.find(charset) if !charset.nil?

    unless assertion_negated( encoding == Encoding::UTF_8 )
      raise AssertionException.new "Response content-type specifies encoding other than UTF-8: #{charset}", header
    end
    unless assertion_negated( (content_type == FHIR::Formats::ResourceFormat::RESOURCE_XML) || (content_type == FHIR::Formats::ResourceFormat::RESOURCE_JSON) )
      raise AssertionException.new "Invalid FHIR content-type: #{content_type}", header
    end
  end

  def assert_etag_present(client_reply)
    header = client_reply.response[:headers]['etag']
    assert assertion_negated( !header.nil? ), 'ETag HTTP header is missing.'
  end

  def assert_last_modified_present(client_reply)
    header = client_reply.response[:headers]['last-modified']
    assert assertion_negated( !header.nil? ), 'Last-modified HTTP header is missing.'
  end

  def assert_valid_content_location_present(client_reply)
    header = client_reply.response[:headers]['location']
    assert assertion_negated( !header.nil? ), 'Location HTTP header is missing.'
  end

  def assert_response_code(response, code)
    unless assertion_negated( code.to_s == response.code.to_s )
      raise AssertionException.new "Bad response code: expected #{code}, but found #{response.code}", response.body
    end
  end

  def assert_resource_type(response, resource_type)
    unless assertion_negated( !response.resource.nil? && response.resource.class == resource_type )
      raise AssertionException.new "Bad response type: expected #{resource_type}, but found #{response.resource.class}.", response.body
    end
  end

  def assert_minimum(response, fixture)
    resource_xml = response.try(:resource).try(:to_xml) || response.try(:body)
    fixture_xml = fixture.try(:to_xml)

    resource_doc = Nokogiri::XML(resource_xml)
    raise "Could not retrieve Resource as XML from response" if resource_doc.root.nil?
    resource_doc.root.add_namespace_definition('fhir', 'http://hl7.org/fhir')

    fixture_doc = Nokogiri::XML(fixture_xml)
    raise "Could not retrieve Resource as XML from fixture" if fixture_doc.root.nil?
    fixture_doc.root.add_namespace_definition('fhir', 'http://hl7.org/fhir')

    # FIXME: This doesn't seem to work for a simple case...needs more work!
    # diffs = []
    # d1 = Nokogiri::XML('<b><p><a>1</a><b>2</b></p><p><a>2</a><b>3</b></p></b>')
    # d2 = Nokogiri::XML('<p><a>2</a><b>3</b></p>')
    # d2.diff(d1, :removed=>true){|change, node| diffs << node.to_xml}
    # diffs.empty? # this returns a list with d2 in it...

    diffs = []
    fixture_doc.diff(resource_doc, :removed => true){|change, node| diffs << node.to_xml}
    diffs.select!{|d| d.strip.length > 0}

    unless assertion_negated( diffs.empty? )
      raise AssertionException.new "Found #{diffs.length} difference(s) between minimum and actual resource.", diffs.to_s
    end
  end

  def assertion_negated(expression)
    if @negated then !expression else expression end
  end

  def skip(message = '')
    raise SkipException.new message
  end

end


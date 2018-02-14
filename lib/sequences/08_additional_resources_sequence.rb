class AdditionalResourcesSequence < SequenceBase

  title 'Additional Resources'

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide Server.'

  preconditions 'Client must be authorized.' do
    !@instance.token.nil?
  end

  test 'Composition not accessible without authorization',
          '',
          '' do
    todo
  end

  test 'Read Composition Resource',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          '' do
    todo

  end

  test 'Search Composition resource supported',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          '',
          :optional do
    todo

  end

  test 'Composition resource valid',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          '' do
    todo

  end
          
  test 'Composition resource contains Section.text',
          '',
          '' do
    todo

  end

  test 'Provenance not accessible without authorization',
          '',
          '' do
    todo
  end

  test 'Read Provenance resource supported',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          '' do
    todo

  end

  test 'Search Provenance resource supported',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          '',
          :optional do
    todo

  end

  test 'Provenance Resource Valid',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          '' do
    todo

  end

  test 'Supports read DSTU2 Provenance Resource',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          '' do
    todo

  end


end

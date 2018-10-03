require_relative '../test_helper'

class TerminologyTest < Minitest::Test

  # turn off the ridiculous warnings
  # $VERBOSE=nil

  @@term_root = File.expand_path '../../resources/terminology',File.dirname(File.absolute_path(__FILE__))

  def setup
    Inferno::Terminology.send(:reset)
    loinc_file = File.join(@@term_root,'terminology_loinc_2000.txt')
    umls_file = File.join(@@term_root,'terminology_umls.txt')
    snomed_file = File.join(@@term_root,'terminology_snomed_core.txt')
    FileUtils.mv(loinc_file, "#{loinc_file}.bak", :force=>true)
    FileUtils.mv(umls_file, "#{umls_file}.bak", :force=>true)
    FileUtils.mv(snomed_file, "#{snomed_file}.bak", :force=>true)
    file = File.open(loinc_file,'w:UTF-8')
    file.write('foo|Foo Description|mg')
    file.close
    file = File.open(umls_file,'w:UTF-8')
    file.write("LOINC|foo|Foo Description\n")
    file.write("RXNORM|placebo|Placebo Description\n")
    file.write("LOINC|bar|Bar Description\n")
    file.close
    file = File.open(snomed_file,'w:UTF-8')
    file.write("baz|Baz Description\n")
    file.close
  end

  def teardown
    loinc_file = File.join(@@term_root,'terminology_loinc_2000.txt')
    umls_file = File.join(@@term_root,'terminology_umls.txt')
    snomed_file = File.join(@@term_root,'terminology_snomed_core.txt')
    FileUtils.rm(loinc_file, :force=>true)
    FileUtils.rm(umls_file, :force=>true)
    FileUtils.rm(snomed_file, :force=>true)
    FileUtils.mv("#{loinc_file}.bak",loinc_file, :force=>true)
    FileUtils.mv("#{umls_file}.bak",umls_file, :force=>true)
    FileUtils.mv("#{snomed_file}.bak",snomed_file, :force=>true)
    Inferno::Terminology.send(:reset)
  end

  def test_get_description_foo
    description = Inferno::Terminology.get_description('LOINC','foo')
    assert description=='Foo Description', "Incorrect description: #{description}"
  end

  def test_get_description_placebo
    description = Inferno::Terminology.get_description('RXNORM','placebo')
    assert description=='Placebo Description', "Incorrect description: #{description}"
  end

  def test_get_description_bar
    description = Inferno::Terminology.get_description('LOINC','bar')
    assert description=='Bar Description', "Incorrect description: #{description}"
  end

  def test_get_description_negative
    description = Inferno::Terminology.get_description('LOINC','baz')
    assert description.nil?, 'Expected nil description.'
  end

  def test_get_description_negative_unknown_system
    description = Inferno::Terminology.get_description('FAKE','fake')
    assert description.nil?, 'Expected nil description.'
  end

  def test_is_top_lab_code_true
    assert Inferno::Terminology.is_top_lab_code?('foo'), 'Top lab code not found.'
  end

  def test_is_top_lab_code_false
    assert !Inferno::Terminology.is_top_lab_code?('bar'), 'Lab code should not have been found.'
  end

  def test_lab_units_foo
    assert Inferno::Terminology.lab_units('foo')=='mg', 'Incorrect units returned.'
  end

  def test_lab_units_bar
    assert Inferno::Terminology.lab_units('bar').nil?, 'Units were unexpectedly returned (should be nil).'
  end

  def test_lab_description_foo
    assert Inferno::Terminology.lab_description('foo')=='Foo Description', 'Incorrect description returned.'
  end

  def test_lab_description_bar
    assert Inferno::Terminology.lab_description('bar').nil?, 'Description was unexpectedly returned (should be nil).'
  end

end
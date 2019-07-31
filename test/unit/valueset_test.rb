# frozen_string_literal: true

require_relative '../test_helper'

class ValueSetTest < Minitest::Test
  def setup
    # Should create a fake database to test with
    @db = SQLite3::Database.new 'valueset_test.db'

    # Create the table
    @db.execute('create table mrconso (
        CUI	char(8) NOT NULL,
        LAT	char(3) NOT NULL,
        TS	char(1) NOT NULL,
        LUI	char(8) NOT NULL,
        STT	varchar(3) NOT NULL,
        SUI	char(8) NOT NULL,
        ISPREF	char(1) NOT NULL,
        AUI	varchar(9) NOT NULL,
        SAUI	varchar(50),
        SCUI	varchar(50),
        SDUI	varchar(50),
        SAB	varchar(20) NOT NULL,
        TTY	varchar(20) NOT NULL,
        CODE	varchar(50) NOT NULL,
        STR	text NOT NULL,
        SRL	int NOT NULL,
        SUPPRESS	char(1) NOT NULL,
        CVF	int
      );')

    insert_into_table = lambda { |concept|
      @db.execute('INSERT INTO mrconso (CUI, LAT, TS, LUI, STT, SUI, ISPREF, AUI, SAB, TTY, CODE, STR, SRL, SUPPRESS, CVF)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', concept)
    }

    new_med = lambda do |code, tty|
      xs = '98'
      [xs, 'ENG', 'A', xs, 'B', xs, 'Y', xs, 'RXNORM', tty, code, 'C', 1, 'N', 1]
    end
    meds = []
    meds << new_med.call('1', 'SCD')
    meds << new_med.call('2', 'SBD')
    meds << new_med.call('3', 'GPCK')
    meds << new_med.call('4', 'BPCK')
    meds << new_med.call('5', 'SCDG')
    meds << new_med.call('6', 'SBDG')
    meds << new_med.call('7', 'SCDF')
    meds << new_med.call('8', 'SBDF')
    meds << new_med.call('9999', 'FAKE')
    meds.each do |med|
      insert_into_table.call(med)
    end
  end

  def teardown
    # Remove the test database
    File.delete('valueset_test.db')
  end

  def test_get_medication_codes_valueset
    vs = Inferno::Terminology::Valueset.new(@db)
    vs.read_valueset('resources/argonauts/ValueSet-medication-codes.json')
    assert vs.valueset.length == 8, 'Expected 8 concepts'
  end

  def test_medication_codes_bloom_filter
    vs = Inferno::Terminology::Valueset.new(@db)
    vs.read_valueset('resources/argonauts/ValueSet-medication-codes.json')
    bf = vs.generate_bloom
    assert bf.count == 8, 'Expected 8 entries in the filter'
    (1..8).each do |n|
      assert bf.include?("http://www.nlm.nih.gov/research/umls/rxnorm|#{n}"), "Expected #{n} to match"
    end
    hits = 0
    total = 0
    (9..1000).each do |n|
      hits += 1 if bf.include?(n)
      total += 1
    end
    assert hits.zero?, 'Expected to invalid codes to match'
    assert !bf.include?('9999'), 'Expected 9999 to fail'
  end
end

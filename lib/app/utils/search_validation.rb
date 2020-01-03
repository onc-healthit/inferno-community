# frozen_string_literal: true

module Inferno
  module SearchValidationUtil
    def get_fhir_datetime_range(datetime)
      range = { start: DateTime.xmlschema(datetime), end: nil }
      range[:end] =
        if /^\d{4}$/.match?(datetime) # YYYY
          range[:start].next_year - 1.seconds
        elsif /^\d{4}-\d{2}$/.match?(datetime) # YYYY-MM
          range[:start].next_month - 1.seconds
        elsif /^\d{4}-\d{2}-\d{2}$/.match?(datetime) # YYYY-MM-DD
          range[:start].next_day - 1.seconds
        else # YYYY-MM-DDThh:mm:ss+zz:zz
          range[:start]
        end
      range
    end

    def get_fhir_period_range(period)
      range = { start: nil, end: nil }
      range[:start] = DateTime.xmlschema(period.start) unless period.start.nil?
      return range if period.end.nil?

      period_end_beginning = DateTime.xmlschema(period.end)
      range[:end] =
        if /^\d{4}$/.match?(period.end) # YYYY
          period_end_beginning.next_year - 1.seconds
        elsif /^\d{4}-\d{2}$/.match?(period.end) # YYYY-MM
          period_end_beginning.next_month - 1.seconds
        elsif /^\d{4}-\d{2}-\d{2}$/.match?(period.end) # YYYY-MM-DD
          period_end_beginning.next_day - 1.seconds
        else # YYYY-MM-DDThh:mm:ss+zz:zz
          period_end_beginning
        end
      range
    end

    def fhir_date_comparer(search_range, target_range, comparator)
      # Implicitly, a missing lower boundary is "less than" any actual date. A missing upper boundary is "greater than" any actual date.
      case comparator
      when 'eq' # the range of the search value fully contains the range of the target value
        !target_range[:start].nil? && !target_range[:end].nil? && search_range[:start] <= target_range[:start] && search_range[:end] >= target_range[:end]
      when 'ne' # the range of the search value does not fully contain the range of the target value
        target_range[:start].nil? || target_range[:end].nil? || search_range[:start] > target_range[:start] || search_range[:end] < target_range[:end]
      when 'gt' #  the range above the search value intersects (i.e. overlaps) with the range of the target value
        target_range[:end].nil? || search_range[:end] < target_range[:end]
      when 'lt' # the range below the search value intersects (i.e. overlaps) with the range of the target value
        target_range[:start].nil? || search_range[:start] > target_range[:start]
      when 'ge'
        fhir_date_comparer(search_range, target_range, 'gt') || fhir_date_comparer(search_range, target_range, 'eq')
      when 'le'
        fhir_date_comparer(search_range, target_range, 'lt') || fhir_date_comparer(search_range, target_range, 'eq')
      when 'sa' # the range above the search value contains the range of the target value
        !target_range[:start].nil? && search_range[:end] < target_range[:start]
      when 'eb' # the range below the search value contains the range of the target value
        !target_range[:end].nil? && search_range[:start] > target_range[:end]
      when 'ap' # the range of the search value overlaps with the range of the target value
        if target_range[:start].nil? || target_range[:end].nil?
          (target_range[:start].nil? && search_range[:start] < target_range[:end]) ||
            (target_range[:end].nil? && search_range[:end] > target_range[:start])
        else
          (search_range[:start] >= target_range[:start] && search_range[:start] <= target_range[:end]) ||
            (search_range[:end] >= target_range[:start] && search_range[:end] <= target_range[:end])
        end
      end
    end

    def validate_date_search(search_value, target_value)
      if target_value.instance_of? FHIR::Period
        validate_period_search(search_value, target_value)
      else
        validate_datetime_search(search_value, target_value)
      end
    end

    def validate_datetime_search(search_value, target_value)
      comparator = search_value[0..1]
      if ['eq', 'ge', 'gt', 'le', 'lt', 'ne', 'sa', 'eb', 'ap'].include? comparator
        search_value = search_value[2..-1]
      else
        comparator = 'eq'
      end
      search_range = get_fhir_datetime_range(search_value)
      target_range = get_fhir_datetime_range(target_value)
      fhir_date_comparer(search_range, target_range, comparator)
    end

    def validate_period_search(search_value, target_value)
      comparator = search_value[0..1]
      if ['eq', 'ge', 'gt', 'le', 'lt', 'ne', 'sa', 'eb', 'ap'].include? comparator
        search_value = search_value[2..-1]
      else
        comparator = 'eq'
      end
      search_range = get_fhir_datetime_range(search_value)
      target_range = get_fhir_period_range(target_value)
      fhir_date_comparer(search_range, target_range, comparator)
    end
  end
end

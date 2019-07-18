# frozen_string_literal: true

module Inferno
  module SearchValidationUtil
    def can_resolve_path(element, path)
      if path.empty?
        return false if element.nil?

        return Array.wrap(element).any? { |el| yield(el) } if block_given?

        return true
      end

      path_ary = path.split('.')
      el_as_array = Array.wrap(element)
      cur_path_part = path_ary.shift.to_sym
      return false if el_as_array.none? { |el| el.try(cur_path_part).present? }

      if block_given?
        el_as_array.any? { |el| can_resolve_path(el.send(cur_path_part), path_ary.join('.')) { |value_found| yield(value_found) } }
      else
        el_as_array.any? { |el| can_resolve_path(el.send(cur_path_part), path_ary.join('.')) }
      end
    end

    def resolve_element_from_path(element, path)
      el_as_array = Array.wrap(element)
      return el_as_array&.first if path.empty?

      path_ary = path.split('.')
      cur_path_part = path_ary.shift.to_sym

      found_subset = el_as_array.select { |el| el.try(cur_path_part).present? }
      return nil if found_subset.empty?

      found_subset.each do |el|
        el_found = resolve_element_from_path(el.send(cur_path_part), path_ary.join('.'))
        return el_found unless el_found.nil?
      end
      nil
    end

    def date_comparator_value(comparator, date)
      case comparator
      when 'lt', 'le'
        comparator + (DateTime.xmlschema(date) + 1).xmlschema
      when 'gt', 'ge'
        comparator + (DateTime.xmlschema(date) - 1).xmlschema
      else
        ''
      end
    end

    def get_fhir_datetime_range(datetime)
      range = { start: DateTime.xmlschema(datetime), end: nil }
      range[:end] =
        if /^\d{4}$/.match?(datetime) # YYYY
          range[:start].next_year
        elsif /^\d{4}-\d{2}$/.match?(datetime) # YYYY-MM
          range[:start].next_month
        elsif /^\d{4}-\d{2}-\d{2}/.match?(datetime) # YYYY-MM-DD
          range[:start].next_day
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
          period_end_beginning.next_year
        elsif /^\d{4}-\d{2}$/.match?(period.end) # YYYY-MM
          period_end_beginning.next_month
        elsif /^\d{4}-\d{2}-\d{2}/.match?(period.end) # YYYY-MM-DD
          period_end_beginning.next_day
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
        !target_range[:start].nil? || !target_range[:end].nil? || search_range[:start] > target_range[:start] || search_range[:end] < target_range[:end]
      when 'gt' #	the range above the search value intersects (i.e. overlaps) with the range of the target value
        target_range[:end].nil? || search_range[:end] <= target_range[:end]
      when 'lt' # the range below the search value intersects (i.e. overlaps) with the range of the target value
        target_range[:start].nil? || search_range[:start] >= target_range[:start]
      when 'ge'
        fhir_date_comparer(search_range, target_range, 'gt') || fhir_date_comparer(search_range, target_range, 'eq')
      when 'le'
        fhir_date_comparer(search_range, target_range, 'lt') || fhir_date_comparer(search_range, target_range, 'eq')
      when 'sa' # the range above the search value contains the range of the target value
        target_range[:start].nil? || search_range[:end] < target_range[:start]
      when 'eb' # the range below the search value contains the range of the target value
        target_range[:end].nil? || search_range[:start] > target_range[:end]
      when 'ap' # the range of the search value overlaps with the range of the target value
        (target_range[:start].nil? && search_range[:start] <= target_range[:end]) ||
          (target_range[:end].nil? && search_range[:end] >= target_range[:start]) ||
          (search_range[:start] >= target_range[:start] && search_range[:start] <= target_range[:end]) ||
          (search_range[:end] >= target_range[:start] && search_range[:end] <= target_range[:end])
      end
    end

    def validate_date_search(search_value, target_value)
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

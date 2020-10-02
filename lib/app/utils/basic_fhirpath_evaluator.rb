# frozen_string_literal: true

module Inferno
  class BasicFHIRPathEvaluator
    def evaluate(elements, path, patched = false)
      path = patch_path(path) unless patched
      elements = Array.wrap(elements)
      return elements if path.blank?

      first_path, *rest_paths = path.split('.')
      rest_path = rest_paths.join('.')

      elements.flat_map do |element|
        evaluate(element&.send(first_path), rest_path, true)
      end.compact
    end

    private

    def patch_path(path)
      path = path.dup
      path.sub!(/^[A-Z]\w*\./, '')
      path.gsub!(/\bclass\b/, 'local_class')
      path.gsub!(/\.where\(.*\)/, '')
      as_type = path.scan(/\.as\((.*?)\)/).flatten.first
      path.gsub!(/\.as\((.*?)\)/, as_type.upcase_first) if as_type.present?
      path
    end
  end
end

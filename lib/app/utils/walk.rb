def walk_resource(resource, path=nil, &block)
  resource.class::METADATA.each do |field_name, meta|
    local_name = meta.fetch :local_name, field_name
    values = [resource.instance_variable_get("@#{local_name}")].flatten.compact
    next if values.empty?

    values.each_with_index do |value, i|
      child_path = if path.nil?
                     field_name
                   elsif meta["max"] > 1
                     "#{path}.#{field_name}[#{i}]"
                   else
                     "#{path}.#{field_name}"
                   end
      yield value, meta, child_path
      walk_resource value, child_path, &block unless FHIR::PRIMITIVES.include? meta["type"]
    end
  end
end

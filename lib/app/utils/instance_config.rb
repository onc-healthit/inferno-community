def configure_instance(instance, arguments)
  arguments.each do |key, val|
    if instance.respond_to?(key)
      if val.is_a?(Array) || val.is_a?(Hash)
        instance.send("#{key.to_s}=", val.to_json) if instance.respond_to? key.to_s
      elsif val.is_a?(String) && val.downcase == 'true'
        instance.send("#{key.to_s}=", true) if instance.respond_to? key.to_s
      elsif val.is_a?(String) && val.downcase == 'false'
        instance.send("#{key.to_s}=", false) if instance.respond_to? key.to_s
      else
        instance.send("#{key.to_s}=", val) if instance.respond_to? key.to_s
      end
    end
  end
  instance
end

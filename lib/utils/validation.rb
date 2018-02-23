class ValidationUtil

  # Cache the Argonaut IG definitions
  argonaut_validation_pack = File.join('resources', 'argonauts', '*.json')
  
  DEFINITIONS = {}
  RESOURCES = {}
  VALUESETS = {}

  Dir.glob(argonaut_validation_pack).each do |definition|
    json = File.read(definition)
    resource = FHIR::DSTU2.from_contents(json)
    DEFINITIONS[resource.url] = resource
    if resource.resourceType == 'StructureDefinition'
      profiled_type = resource.snapshot.element.first.path
      RESOURCES[profiled_type] = [] unless RESOURCES[profiled_type]
      RESOURCES[profiled_type] << resource
    elsif resource.resourceType == 'ValueSet'
      VALUESETS[resource.url] = resource
    end
  end

  SMOKING_STATUS_URL = 'http://fhir.org/guides/argonaut/StructureDefinition/argo-smokingstatus'
  OBSERVATION_RESULTS_URL = 'http://fhir.org/guides/argonaut/StructureDefinition/argo-observationresults'
  VITAL_SIGNS_URL = 'http://fhir.org/guides/argonaut/StructureDefinition/argo-vitalsigns'
  CARE_TEAM_URL = 'http://fhir.org/guides/argonaut/StructureDefinition/argo-careteam'
  CARE_PLAN_URL = 'http://fhir.org/guides/argonaut/StructureDefinition/argo-careplan'
  
  def self.guess_profile(resource)
    if resource
      # if the profile is given, we don't need to guess
      if resource.meta && resource.meta.profile && !resource.meta.profile.empty?
        resource.meta.profile.each do |uri|
          return DEFINITIONS[uri] if DEFINITIONS[uri]
        end
      end
      candidates = RESOURCES[resource.resourceType]
      if candidates && !candidates.empty?
        # Special cases where there are multiple profiles per Resource type
        if resource.resourceType == 'Observation'
          if resource.code && resource.code.coding && resource.code.coding.first && resource.code.coding.first.code == '72166-2'
            return DEFINITIONS[SMOKING_STATUS_URL]
          elsif resource.category && resource.category.coding && resource.category.coding.first && resource.category.coding.first.code == 'laboratory'
            return DEFINITIONS[OBSERVATION_RESULTS_URL]
          elsif resource.category && resource.category.coding && resource.category.coding.first && resource.category.coding.first.code == 'vital-signs'
            return DEFINITIONS[VITAL_SIGNS_URL]
          end
        elsif resource.resourceType == 'CareTeam'
          if resource.category && resource.category.coding && resource.category.coding.first && resource.category.coding.first.code = 'careteam'
            return DEFINITIONS[CARE_TEAM_URL]
          else
            return DEFINITIONS[CARE_PLAN_URL]
          end
        end
        # Otherwise, guess the first profile that matches on resource type
        return candidates.first
      end
    end
    nil
  end
end
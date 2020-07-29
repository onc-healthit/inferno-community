Instance: mCODERequirements
InstanceOf: CapabilityStatement
Title: "mCODE Server requirements"
Usage: #definition
* name = "mCODEServerRequirements"
* status = #draft
* date = "2020-06-01"
* kind = #requirements
* fhirVersion = #4.0.1
* format = #json
* implementationGuide = "http://hl7.org/fhir/us/mcode/ImplementationGuide/hl7.fhir.us.mcode"
* description = "These are the read and search requirements of an mCODE Server"
* rest.mode = #server
* rest.documentation = """
mCODE Server RESTful API Read Requirements
"""

* rest.resource[0].type = #Condition
* rest.resource[0].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-condition-parent"
// The profile SHALL support Read
* rest.resource[0].interaction[0].code = #read
* rest.resource[0].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[0].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[1].type = #Observation
* rest.resource[1].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-disease-status"
// The profile SHALL support Read
* rest.resource[1].interaction[0].code = #read
* rest.resource[1].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[1].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[2].type = #Observation
* rest.resource[2].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-genetic-variant"
// The profile SHALL support Read
* rest.resource[2].interaction[0].code = #read
* rest.resource[2].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[2].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[3].type = #DiagnosticReport
* rest.resource[3].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-genomics-report"
// The profile SHALL support Read
* rest.resource[3].interaction[0].code = #read
* rest.resource[3].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[3].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[4].type = #Patient
* rest.resource[4].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient"
// The profile SHALL support Read
* rest.resource[4].interaction[0].code = #read
* rest.resource[4].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[4].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[5].type = #MedicationStatement
* rest.resource[5].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-medication-statement"
// The profile SHALL support Read
* rest.resource[5].interaction[0].code = #read
* rest.resource[5].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[5].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[6].type = #Procedure
* rest.resource[6].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-radiation-procedure"
// The profile SHALL support Read
* rest.resource[6].interaction[0].code = #read
* rest.resource[6].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[6].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[7].type = #Procedure
* rest.resource[7].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-surgical-procedure"
// The profile SHALL support Read
* rest.resource[7].interaction[0].code = #read
* rest.resource[7].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[7].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[8].type = #Observation
* rest.resource[8].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-stage-parent"
// The profile SHALL support Read
* rest.resource[8].interaction[0].code = #read
* rest.resource[8].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[8].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[9].type = #Condition
* rest.resource[9].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-comorbid-condition"
// The profile SHALL support Read
* rest.resource[9].interaction[0].code = #read
* rest.resource[9].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[9].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[10].type = #Observation
* rest.resource[10].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-ecog-performance-status"
// The profile SHALL support Read
* rest.resource[10].interaction[0].code = #read
* rest.resource[10].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[10].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[11].type = #Specimen
* rest.resource[11].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-genetic-specimen"
// The profile SHALL support Read
* rest.resource[11].interaction[0].code = #read
* rest.resource[11].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[11].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[12].type = #Observation
* rest.resource[12].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-genomic-region-studied"
// The profile SHALL support Read
* rest.resource[12].interaction[0].code = #read
* rest.resource[12].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[12].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[13].type = #Observation
* rest.resource[13].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-karnofsky-performance-status"
// The profile SHALL support Read
* rest.resource[13].interaction[0].code = #read
* rest.resource[13].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[13].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[14].type = #Condition
* rest.resource[14].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-primary-cancer-condition"
// The profile SHALL support Read
* rest.resource[14].interaction[0].code = #read
* rest.resource[14].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[14].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[15].type = #Condition
* rest.resource[15].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-secondary-cancer-condition"
// The profile SHALL support Read
* rest.resource[15].interaction[0].code = #read
* rest.resource[15].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[15].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[16].type = #Observation
* rest.resource[16].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-clinical-distant-metastases-category"
// The profile SHALL support Read
* rest.resource[16].interaction[0].code = #read
* rest.resource[16].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[16].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[17].type = #Observation
* rest.resource[17].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-clinical-primary-tumor-category"
// The profile SHALL support Read
* rest.resource[17].interaction[0].code = #read
* rest.resource[17].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[17].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[18].type = #Observation
* rest.resource[18].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-clinical-regional-nodes-category"
// The profile SHALL support Read
* rest.resource[18].interaction[0].code = #read
* rest.resource[18].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[18].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[19].type = #Observation
* rest.resource[19].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-clinical-stage-group"
// The profile SHALL support Read
* rest.resource[19].interaction[0].code = #read
* rest.resource[19].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[19].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[20].type = #Observation
* rest.resource[20].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-pathological-distant-metastases-category"
// The profile SHALL support Read
* rest.resource[20].interaction[0].code = #read
* rest.resource[20].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[20].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[21].type = #Observation
* rest.resource[21].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-pathological-primary-tumor-category"
// The profile SHALL support Read
* rest.resource[21].interaction[0].code = #read
* rest.resource[21].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[21].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[22].type = #Observation
* rest.resource[22].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-pathological-regional-nodes-category"
// The profile SHALL support Read
* rest.resource[22].interaction[0].code = #read
* rest.resource[22].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[22].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[23].type = #Observation
* rest.resource[23].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tnm-pathological-stage-group"
// The profile SHALL support Read
* rest.resource[23].interaction[0].code = #read
* rest.resource[23].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[23].interaction[0].extension[0].valueCode = #SHALL

* rest.resource[24].type = #Observation
* rest.resource[24].supportedProfile = "http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-tumor-marker"
// The profile SHALL support Read
* rest.resource[24].interaction[0].code = #read
* rest.resource[24].interaction[0].extension.url = "http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation"
* rest.resource[24].interaction[0].extension[0].valueCode = #SHALL

## Optional Terminology Support

The scorecard requires some terminology files to operate several rubrics related
to codes. Download the files (requires accounts) and place them here in `./resources/terminology`

- https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html
 - When installing the metathesaurus, include the following sources:
  `CVX|CVX;
   ICD10CM|ICD10CM;
   ICD10PCS|ICD10PCS;
   ICD9CM|ICD9CM;
   LNC|LNC;
   MTHICD9|ICD9CM;
   RXNORM|RXNORM;
   SNOMEDCT_US|SNOMEDCT`

- https://www.nlm.nih.gov/research/umls/Snomed/core_subset.html
- https://loinc.org/download/loinc-top-2000-lab-observations-us-csv/
- http://download.hl7.de/documents/ucum/concepts.tsv

After downloading the files, run these rake tasks to post-process each terminology file:

```
> bundle exec rake terminology:process_umls
> bundle exec rake terminology:process_snomed
> bundle exec rake terminology:process_loinc
> bundle exec rake terminology:process_ucum
```
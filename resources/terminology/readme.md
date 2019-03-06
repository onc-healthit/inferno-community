## Optional Terminology Support

In order to validate terminologies Inferno can be loaded with files generated from the 
Unified Medical Language System (UMLS).  The UMLS is distributed by the National Library of Medicine (NLM)
and requires an account to access.

Inferno provides some rake tasks which may make this process easier.

### Downloading the UMLS

Inferno provides a task which attempts to download the UMLS for you:

```sh
bundle exec rake terminology:download_umls[username, password]
```

*Note: username and passwords should be entered as strings to avoid issues with special characters.  For example*
```sh
bundle exec rake terminology:download_umls['jsmith','hunter2!']
```

This command requires a valid UMLS `username` and `password`.  Inferno does not store this information and 
only uses it to download the necessary files during this step.

If this command fails, or you do not have a UMLS account, the file can be
downloaded directly from the UMLS website.

https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.htm

### Unzipping the UMLS files
The UMLS files should be decompressed for processing and use.  The metamorphoSys utility provided
within the UMLS distribution must be unzipped as well.

Inferno provides a task which will attempt to unzip the files into the correct location
for further operation:

```sh
bundle exec rake terminology:unzip_umls
```

Users can also manually unzip the files.  The mmsys.zip file should be unzipped to the same
directory as the other downloaded files.

See https://www.nlm.nih.gov/research/umls/implementation_resources/metamorphosys/help.html#screens_tabs
for more details.

### Creating a UMLS Subset

The metamorphoSys tool can customize and install UMLS sources.  Inferno provides
a configuration file and a task to help run the metamorphoSys tool.

```sh
bundle exec rake terminology:run_umls
```

The UMLS tool can also be manually executed.

*Note: This step can take a while to finish*

### Loading the subset

Inferno loads the UMLS subset into a SQLite database for executing the queries which support creating the terminology validators.
A shell script is provided at the root of the project to automatically create the database

```sh
./create_umls.sh
```

### Creating the Terminology Validators

Once the UMLS database has been created the terminology validators can be created for Inferno's use.

```sh
bundle exec rake terminology:create_vs_validators
```

### Cleaning up
The UMLS distribution is large and no longer required by Inferno after processing.

Inferno provides a utility which removes the umls.zip file, the unzipped distribution, and the
installed subset

```sh
bundle exec rake terminology:cleanup_umls
```

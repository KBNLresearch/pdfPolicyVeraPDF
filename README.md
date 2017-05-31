# PDF policy-based validation demo, veraPDF

## About

Simple shell script that demonstrates policy-based validation of PDF documents using [VeraPDF](http://verapdf.org/). Each file with a .pdf extension in a user-defined directory is analysed with VeraPDF, and assessed against a  user-specified schema (which represents a policy).

## Author
Johan van der Knijff, KB/National Library of the Netherlands

## Dependencies

- *VeraPDF* (tested with version 1.4.7) + dependencies (Java)
- *python* (tested with version 2.7.6)

## Contents of this repo

- **policyValidate.sh**: demo script

- **postprocessing.py**: Python script that post-processes the veraPDF output file

- **schemas**: example schemas (currently only one)


## VeraPDF configuration

The policy-based validation uses the VeraPDF feature-extraction switch. In order for this to work correctly, activate reporting of the following features by editing VeraPDF's configuration file as below (can also be done from GUI / Config menu):

    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <featuresConfig>
        <enabledFeatures>
            <feature>ANNOTATION</feature>
            <feature>DOCUMENT_SECURITY</feature>
            <feature>EMBEDDED_FILE</feature>
            <feature>FONT</feature>
            <feature>INFORMATION_DICTIONARY</feature>
        </enabledFeatures>
    </featuresConfig>


## Command line use

#### Usage

    policyValidate.sh pdfDir policy

#### Positional arguments

`pdfDir` : input directory (directory is *not* processed recursively!)

`policy` : schematron file that defines the policy (see example in the *schemas* directory)

## Output

The script produces the following output files:

- **index.csv**: comma-delimited text file with for each analysed PDF the paths to the corresponding VeraPDF and Schematron output files
- **success.csv**: comma-delimited text file with for each analysed PDF the outcome of the policy-based validation (pass/fail)
- **failed.csv**:  text file with all tests that failed for PDFs that failed the policy-based validation

In addition, the raw output files of *VeraPDF* and the Schematron validation are written to directory *outRaw*. You should use *index.csv* to link each of these files to their corresponding PDF. 

## Example

`policyValidate.sh myPDFs demo-policy.sch`


 

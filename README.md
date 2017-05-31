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

    policyValidate.sh pdfDir policy suffixOut

#### Positional arguments

`pdfDir` : input directory (directory is *not* processed recursively!)

`policy` : schematron file that defines the policy (see example in the *schemas* directory)

`suffixOut` : suffix that is used as base name for output files

## Output

The script produces the following output files:

- **suffixOut_out.xml**: output file of VeraPDF
- **suffixOut_san.xml**: sanitised version of VeraPDF output file. For each PDFit only contains the Policy Report, with duplicate instances of failed checks removed.
- **suffixOut_summary.csv**:  comma-delimited file with for each PDF the file reference, followed by the description of each unique failed validation rule (taken from *message* element in VeraPDF output).


## Example

`policyValidate.sh myPDFs demo-policy.sch whatever`


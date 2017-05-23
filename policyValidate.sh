#!/bin/bash

# Simple demo script that demonstrates minimal workflow for policy-based validation of PDFs 
# using veraPDF and Schematron.
#
# Each file with a .pdf extension in the directory tree is analysed with VeraPDF, 
# and the VeraPDF output is subsequently validated against a  user-specified schema (which represents a policy).
#
# Author: Johan van der Knijff, KB/National Library of the Netherlands
#
# Dependencies and requirements:
#
# - java
# - VeraPDF  (tested with v. 1.4.6) 
# - xsltproc (part of libxslt library)
# - xmllint (part of libxml library)
# - If you're using Windows you can run this shell script within a Cygwin terminal: http://www.cygwin.com/

# **************
# CONFIGURATION
# **************

# Location of VeraPDF CLI script -- update according to your local installation!
veraPDF=/home/johan/verapdf/verapdf

# Do not edit anything below this line (unless you know what you're doing) 

# Installation directory
instDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Location of Schematron XSL files
xslPath=$instDir/iso-schematron-xslt1

# **************
# USER I/O
# **************

# Check command line args
if [ "$#" -ne 2 ] ; then
  echo "Usage: policyValidate.sh rootDirectory policy" >&2
  exit 1
fi

if ! [ -d "$1" ] ; then
  echo "rootDirectory must be a directory" >&2
  exit 1
fi

if ! [ -f "$2" ] ; then
  echo "policy must be a file" >&2
  exit 1
fi

# EPUB root directory
docRoot="$1"

# Schema
schema="$2"

# **************
# CREATE OUTPUT DIRECTORY FOR RAW EPUBCHECK / SCHEMATRON FILES
# **************
rawDir="outRaw"
if ! [ -d $rawDir ] ; then
    mkdir $rawDir
fi

# Normalise to absolute path
# rawDir=$(realpath ./$rawDir)
rawDir=$(readlink -f $rawDir)

# **************
# OUTPUT FILES
# **************

# Links each PDF to corresponding Epubcheck / Schematron output file
indexFile="index.csv"

# File with results (pass/fail) of policy-based validation for each EPUB 
successFile="success.csv"

# File that summarises failed tests for EPUBs that didn't pass policy-based validation
failedTestsFile="failed.csv" 

# Remove these files if they exist already (writing to them will be done in append mode!)

if [ -f $indexFile ] ; then
    rm $indexFile
fi

if [ -f $successFile ] ; then
    rm $successFile
fi

if [ -f $failedTestsFile ] ; then
    rm $failedTestsFile
fi

# **************
# MAIN PROCESSING LOOP
# **************

counter=0

# Select all files with extension .pdf.
# Now works for filenames that contain whitespace using code adapted from:
# http://stackoverflow.com/questions/7039130/bash-iterate-over-list-of-files-with-spaces/7039579#7039579

while IFS= read -d $'\0' -r file ; do
    docName="$file"
    counter=$((counter+1))
    
    # Generate names for output files, based on counter
    outputVeraPDF=$rawDir/"$counter"_verapdf.xml
    outputSchematron=$rawDir/"$counter"_schematron.xml
    
    # Run VeraPDF
    $veraPDF -x "$docName" > $outputVeraPDF 2>tmp.stderr
    
    # Validate output using Schematron reference application
    if [ $counter == "1" ]; then
        # We only need to generate xx1.sch, xx2.sch and xxx.xsl once
        xsltproc --path $xslPath $xslPath/iso_dsdl_include.xsl $schema > xxx1.sch
        xsltproc --path $xslPath $xslPath/iso_abstract_expand.xsl xxx1.sch > xxx2.sch
        xsltproc --path $xslPath $xslPath/iso_svrl_for_xslt1.xsl xxx2.sch > xxx.xsl
    fi
    
    xsltproc --path $xslPath xxx.xsl $outputVeraPDF > $outputSchematron
    
    # Extract failed tests from Schematron output
    
    # Line below extracts literal test
    failedTests=$(xmllint --xpath "//*[local-name()='schematron-output']/*[local-name()='failed-assert']/@test" $outputSchematron)
    
    # Line below extracts text description of failed tests (each wrapped in <svrl:text> element, ugly but I've already spent too much time trying
    # to get rid of them and all the solutions I've seen for this are ridiculously complicated and I have other things to do anyway)
    #failedTests=$(xmllint --xpath "//*[local-name()='schematron-output']/*[local-name()='failed-assert']/*[local-name()='text']" $outputSchematron)
    
    # This is just in case anything went wrong with the Schematron validation
    schematronFileSize=$(wc -c < $outputSchematron)
    
    if [ $schematronFileSize == 0 ]; then
        failedTests="SchematronFailure"
    fi
    
    # PDF passed policy-based validation if failedTests is empty 
    if [ ! "$failedTests" ]
    then
        success="Pass"
    else
        success="Fail"
        # Failed tests to output file
        echo \"$docName\",$failedTests >> $failedTestsFile
    fi
    
    # Write index file (links VeraPDF and Schematron outputs to each EPUB)
    echo \"$docName\",\"$outputVeraPDF\",\"$outputSchematron\" >> $indexFile
    
    # Write success file (lists validation outcome for each PDF)
    echo \"$docName\",$success >> $successFile
    
done < <(find $docRoot -name '*.pdf' -type f -print0)

# **************
# CLEAN-UP
# **************

rm xxx1.sch
rm xxx2.sch
rm xxx.xsl
rm tmp.stderr

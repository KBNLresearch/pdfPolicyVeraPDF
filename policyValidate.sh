#!/bin/bash

# Simple demo script that demonstrates minimal workflow for policy-based validation of PDFs 
# using veraPDF. Requirements:
#
# * veraPDF
# * Python with lxml (tested with Python 2.7) 

# **************
# CONFIGURATION
# **************

# Installation directory
instDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Location of VeraPDF CLI script -- update according to your local installation!
veraPDF=~/verapdf/verapdf

# Location of post-processing script
extractScript=$instDir/postprocessing.py

# Do not edit anything below this line (unless you know what you're doing) 

# **************
# USER I/O
# **************

# Check command line args
if [ "$#" -ne 2 ] ; then
  echo "Usage: policyValidate.sh pdfDir policy" >&2
  exit 1
fi

if ! [ -d "$1" ] ; then
  echo "pdfDir must be a directory" >&2
  exit 1
fi

if ! [ -f "$2" ] ; then
  echo "policy must be a file" >&2
  exit 1
fi

# PDF directory
pdfDir="$1"

# Schema
schema="$2"

# **************
# OUTPUT FILES
# **************

veraOut=veraOut.xml
veraCleaned=veraCleaned.xml

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
# PROCESSING
# **************

# Run VeraPDF
$veraPDF -x --maxfailuresdisplayed 1 --policyfile $schema $pdfDir/*.pdf > $veraOut

# Run post-processing script
python $extractScript $veraOut > $veraCleaned


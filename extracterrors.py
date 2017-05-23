#! /usr/bin/env python

# This script extracts ERROR messages (not warnings!) from Epubcheck files
# that failed validation. 
# Johan van der Knijff, KB/ National Library of the Netherlands
#

import imp
import os
import sys
import xml.etree.ElementTree as ET
import argparse
import collections


def main_is_frozen():
    return (hasattr(sys, "frozen") or # new py2exe
            hasattr(sys, "importers") # old py2exe
            or imp.is_frozen("__main__")) # tools/freeze
    
def get_main_dir():
    if main_is_frozen():
        return os.path.dirname(sys.executable)
    return os.path.dirname(sys.argv[0])

def errorExit(msg):
    msgString=("ERROR: " +msg + "\n")
    sys.stderr.write(msgString)
    sys.exit()
    
def addPath(pathIn,fileIn):
    result=os.path.normpath(pathIn+ "/" + fileIn)
    return(result)

def parseCommandLine():
    # Create parser
    parser = argparse.ArgumentParser(description="Extract errors from raw epubcheck output")
 
    # Add arguments
    parser.add_argument('dirIn', action="store", help="input directory")
    
    # Parse arguments
    args=parser.parse_args()
    
    # Normalise all file paths
    args.fileIn=os.path.normpath(args.dirIn)
    
    return(args)

def getFilesFromDir(dirpath):
    existingFiles = []    
    for fp in os.listdir(dirpath):
        filepath = os.path.join(dirpath, fp)
        if os.path.isfile(filepath):
            existingFiles.append(filepath)
    return(existingFiles)
    
def getErrors(epubcheckXML):
    
    # Parse epubcheck output; if not wel formed return uri, status, version and list of all validation error messages
       
    errors = []

    tree=ET.parse(epubcheckXML)
    root = tree.getroot()
    
    containsMessages = False
    
    for element in root:
    
        if element.tag == '{http://hul.harvard.edu/ois/xml/ns/jhove}repInfo':
            repInfo = element
            uri = repInfo.get("uri")
      
    for element in repInfo:
    
        if element.tag == '{http://hul.harvard.edu/ois/xml/ns/jhove}status':
            status = element.text
        if element.tag == '{http://hul.harvard.edu/ois/xml/ns/jhove}version':
            version = element.text
        if element.tag == '{http://hul.harvard.edu/ois/xml/ns/jhove}messages':
            containsMessages =True
            messages = element
    
    if containsMessages == True:        
        for element in messages:
            if "ERROR" in element.text:
                errors.append(element.text)
    
    return(uri, status, version, errors)    
    
def main():

    # What is the location of this script/executable
    appPath=os.path.abspath(get_main_dir())

    # Get input from command line 
    args=parseCommandLine()
    dirIn=args.dirIn
            
    # Check if dirIn exists, and exit if not
    if os.path.isdir(dirIn)==False:
        msg=dirIn + " does not exist!"
        errorExit(msg)

    dirIn =  os.path.abspath(dirIn)

    # All files in input dir
    myFiles = getFilesFromDir(dirIn)
        
    # Main processing loop; each item represents one epubcheck output file
    
    filesWithFallbackError = []
    noFilesWithFallbackError = 0
       
    for thisFile in myFiles:
        uri, status, version, errors = getErrors(thisFile)
        containsFallbackError = False
        
        if status == "Not well-formed":
            print(uri)
            print(status)
            print(version)
            for error in errors:
                if "A fallback must be specified" not in error:
                    containsFallbackError = True
                else:
                    print(error)
                
            print("----")
        
        if containsFallbackError == True:
            noFilesWithFallbackError += 1
            filesWithFallbackError.append(uri)
        
    print("Fallback error count: " + str(noFilesWithFallbackError))
    
    
                        
    """
    # Count occurrences for each error/exception
    errorOccurrences=collections.Counter(preflightErrorsAllFiles)
    errorOccurencesCounts=errorOccurrences.most_common()
    
    # Same for failed assertions
    failedAssertionOccurrences=collections.Counter(failedAssertionsAllFiles)
    failedAssertionOccurrencesCounts=failedAssertionOccurrences.most_common()
    
    # Write results to file    
    f = open("preflightErrorCounts.csv", 'w')
    for item in errorOccurencesCounts:
        f.write(item[0] + ','  + str(item[1]) + "\n")
    f.close()
    
    f = open("failedAssertCounts.csv", 'w')
    for item in failedAssertionOccurrencesCounts:
        f.write('"' + item[0] + '",'  + str(item[1]) + "\n")
    f.close()
    """

main()

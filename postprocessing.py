#! /usr/bin/env python
import os
import io
import sys
import codecs
import argparse
from lxml import etree
from xml.dom import minidom

# This script returns a slimmed-down version of a VeraPDF output file that contains, for each job:
# * 'name' element
# * 'policyReport/failedCheck's elements, containing one or more 'check' subelements
# * duplicate 'check' elements within a job are left out (based on value of 'test' attribute) 

# Create parser
parser = argparse.ArgumentParser(
description="Extract policy report from VeraPDF output")

def parseCommandLine():
    # Add arguments
    
    # Sub-parsers for check and write commands

    parser.add_argument('fileVeraPDF',
                        action="store",
                        type=str,
                        help="VeraPDF output file")
    # Parse arguments
    args = parser.parse_args()

    return(args)

def writeElement(elt, codec):
    # Writes element as XML to stdout using defined codec

    # Element to string
    if sys.version.startswith("2"):
        xmlOut = etree.tostring(elt,encoding='UTF-8')
    if sys.version.startswith("3"):
        xmlOut = etree.tostring(elt,encoding='UTF-8')

    # Make xml pretty
    xmlPretty = minidom.parseString(xmlOut).toprettyxml('    ')
    xmlOut = xmlPretty
       
    # Write output
    codec.write(xmlOut)

def main():    
    # Set encoding of the terminal to UTF-8
    if sys.version.startswith("2"):
        out = codecs.getwriter("UTF-8")(sys.stdout)
        err = codecs.getwriter("UTF-8")(sys.stderr)
    elif sys.version.startswith("3"):
        out = codecs.getwriter("UTF-8")(sys.stdout.buffer)
        err = codecs.getwriter("UTF-8")(sys.stderr.buffer)

    # Configure XML parser to get rid of blank lines
    parser = etree.XMLParser(remove_blank_text=True)

    # Get input from command line
    args = parseCommandLine()
    # veraPDF output file
    fileVeraPDF = args.fileVeraPDF
       
    treeIn = etree.parse(fileVeraPDF, parser=parser)
    treeOut = etree.Element("report")
    jobsOut = etree.Element("jobs")
     
    for job in treeIn.findall('//jobs/job'):
        jobOut = etree.Element("job")
        item = job.find('item')        
        policyReport = job.find('policyReport')
        policyReportOut = etree.Element("policyReport")
        failedChecks = policyReport.find('failedChecks')
        failedChecksOut = etree.Element("failedChecks")
        testIDs = []
        for check in failedChecks.findall('check'):
            testID = check.attrib["test"]
            if testID not in testIDs:
                failedChecksOut.append(check)
                testIDs.append(testID)
        
        policyReportOut.append(failedChecksOut)
        
        jobOut.append(item)
        jobOut.append(policyReportOut)
        jobsOut.append(jobOut)


    treeOut.append(jobsOut)
            
    writeElement(treeOut, out)
    

main()


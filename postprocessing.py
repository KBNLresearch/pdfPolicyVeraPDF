#! /usr/bin/env python
import os
import io
import sys
import csv
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
    parser.add_argument('fileOut',
                        action="store",
                        type=str,
                        help="Sanitised output file")
    parser.add_argument('csvOut',
                        action="store",
                        type=str,
                        help="Summary CSV file")
    # Parse arguments
    args = parser.parse_args()

    return(args)

def writeElement(elt, fileName):
    # Writes element as XML

    # Element to string
    if sys.version.startswith("2"):
        xmlOut = etree.tostring(elt,encoding='UTF-8')
    if sys.version.startswith("3"):
        xmlOut = etree.tostring(elt,encoding='UTF-8')

    # Make xml pretty
    xmlPretty = minidom.parseString(xmlOut).toprettyxml('    ')
    xmlOut = xmlPretty
       
    # Write output
    
    with io.open(fileName, "wt", encoding="utf-8") as fOut:
        fOut.write(xmlOut) 


def main():    

    # Configure XML parser to get rid of blank lines
    parser = etree.XMLParser(remove_blank_text=True)

    # Get input from command line
    args = parseCommandLine()
    # veraPDF file
    fileVeraPDF = args.fileVeraPDF
    # Sanitised output file
    fileOut = args.fileOut
    # Summary CSV file
    csvOut = args.csvOut
    
    # Open csvOut in append mode
    if sys.version.startswith('3'):
        # Py3: csv.reader expects file opened in text mode
        fCSV = open(csvOut,"wt", encoding="utf-8")
    elif sys.version.startswith('2'):
        # Py2: csv.reader expects file opened in binary mode
        fCSV = open(csvOut,"wb")
        
    # Create CSV writer object
    csvW = csv.writer(fCSV, lineterminator='\n')
       
    treeIn = etree.parse(fileVeraPDF, parser=parser)
    treeOut = etree.Element("report")
    jobsOut = etree.Element("jobs")
     
    for job in treeIn.findall('//jobs/job'):
        jobOut = etree.Element("job")
        item = job.find('item')
        name = item.find('name')      
        policyReport = job.find('policyReport')
        policyReportOut = etree.Element("policyReport")
        failedChecks = policyReport.find('failedChecks')
        failedChecksOut = etree.Element("failedChecks")
        testIDs = []
        row = [name.text]
        for check in failedChecks.findall('check'):
            testID = check.attrib["test"]
            if testID not in testIDs:
                message = check.find('message')
                failedChecksOut.append(check)
                testIDs.append(testID)
                row.append(message.text)
        
        policyReportOut.append(failedChecksOut)
        
        jobOut.append(item)
        jobOut.append(policyReportOut)
        jobsOut.append(jobOut)
        
        # write row to CSV file
        csvW.writerow(row)


    treeOut.append(jobsOut)
            
    writeElement(treeOut, fileOut)
    fCSV.close()
    

main()


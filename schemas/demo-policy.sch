<?xml version="1.0"?>
<!--
Schematron rules for policy-based  validation of PDF, based on output of VeraPDF.
   
The current set of rules represents the following policy:
   * No encryption / password protection
   * All fonts are embedded
   * No JavaScript
   * No embedded files (i.e. file attachments)
   * No multimedia content (audio, video, 3-D objects)
   * No PDFs that raise exception or result in processing error in VeraPDF (PDF validity proxy) 
-->

<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt">
    <sch:pattern name="Disallow encryption.">
        <sch:rule context="/report/jobs/job/featuresReport/documentSecurity">
            <sch:assert test="not(encryptMetadata = 'true')">Encrypt in trailer dictionary is not allowed.</sch:assert>
        </sch:rule>
        <sch:rule context="/report/batchSummary">
            <sch:assert test="not(@encrypted='1')">Encryption with open password is not allowed.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern name="Fonts must be embedded.">
        <sch:rule context="/report/jobs/job/featuresReport/documentResources/fonts/font/fontDescriptor">
            <sch:assert test="not(embedded = 'false')">Fonts that are not embedded are not allowed.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern name="Multimedia not allowed.">
        <sch:rule context="/report/jobs/job/featuresReport/annotations/annotation">
            <sch:assert test="not(subType='Screen')">Document must be parsable.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern name="File attachments and embeedded files not allowed.">
        <sch:rule context="/report/jobs/job/featuresReport/annotations/annotation">
            <sch:assert test="not(subType='FileAttachment')">File attachments are not allowed.</sch:assert>
        </sch:rule>
        <sch:rule context="/report/jobs/job/featuresReport/embeddedFiles">
            <sch:assert test="not('embeddedFile')">Embedded files are not allowed.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern name="Document must be parsable (poor man's proxy for canonical PDF validation).">
        <sch:rule context="/report/jobs/job/taskResult">
            <sch:assert test="not(@type='PARSE' and @isSuccess='false')">Document must be parsable.</sch:assert>
        </sch:rule>
    </sch:pattern>
    
</sch:schema>


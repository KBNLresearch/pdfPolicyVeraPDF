<?xml version="1.0"?>
<!--
Schematron rules for policy-based  validation of PDF, based on output of VeraPDF.
   
The current set of rules represents the following policy:
   * No encryption / password protection
-->

<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt">
    <sch:pattern name="Disallow encryption.">
        <sch:rule context="/report/jobs/job/featuresReport/documentSecurity">
            <sch:assert test="not(encryptMetadata = 'true')">Encrypt in trailer dictionary is not allowed.</sch:assert>
        </sch:rule>
        <sch:rule context="/report/jobs/job/taskResult/exceptionMessage">
            <sch:assert test="not(contains(.,'encrypted'))">Encryption with open password is not allowed.</sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>


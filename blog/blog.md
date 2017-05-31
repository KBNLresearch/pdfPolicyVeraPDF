# Re-analysis of Adobe Acrobat Engineering test files

Almost four years ago I wrote [a blog post](http://openpreservation.org/blog/2013/07/25/identification-pdf-preservation-risks-sequel/) that demonstrated how *Apache Preflight* (the PDF/A validator tool that is part of [*Apache PDFBox*](https://pdfbox.apache.org/)) can be used to detect features in a PDF that are potential preservation risks. A [follow-up blog](http://openpreservation.org/blog/2014/01/27/identification-pdf-preservation-risks-analysis-govdocs-selected-corpus/) applied [*Schematron*](https://en.wikipedia.org/wiki/Schematron) rules to the *Preflight* output in an attempt at doing policy-based assessments. The results of that work were quite promising, but dealing with Preflight's multitude of (especially font-related) validation errors proved to be a challenge.   

The idea of using a *PDF/A* validor for policy-based assessments of "regular" *PDF* files (i.e. *PDF*s that are not necessarily *PDF/A*) was explicitly addressed as a use case for [*veraPDF*](http://verapdf.org/). With *VeraPDF* now having entered its "final testing phase", I thought this was a good time for a small test-drive of *veraPDF*'s capabilities in this area.

## Test data
  
For this test I used *PDF*s from the [*Adobe Acrobat Engineering* website](https://web.archive.org/web/20130503115947/http://acroeng.adobe.com/wp/) (sadly gone since 2015). As in my 2013 blog post, I limited the analysis to:

* all files in the *General* section of the [*Font Testing*](https://web.archive.org/web/20150228065249/http://acroeng.adobe.com:80/wp/?page_id=101) category;
* all files in the *Classic Multimedia* section of the [*Multimedia & 3D Tests*](https://web.archive.org/web/20150228104639/http://acroeng.adobe.com:80/wp/?page_id=61) category.

This dataset is small, but quite challenging (especially the files in the multimedia category).
 
## Policy

The policy is similar to the one used in [my 2014 blog post](http://openpreservation.org/blog/2014/01/27/identification-pdf-preservation-risks-analysis-govdocs-selected-corpus/), and it is defined by the following objectives:

1. No encryption / password protection
2. All fonts are embedded
3. No embedded files
4. No file attachments
5. No multimedia content (audio, video, 3-D objects)
6. No PDFs that raise exception or result in processing error in VeraPDF (PDF validity proxy) 

(Note that the 2014 blog post also mentioned the absence of *JavaScript* as an additional objective. However, it turned out that the necessary output for this is not currently reported by *VeraPDF*. See [this ticket](https://github.com/veraPDF/veraPDF-apps/issues/174) on Github for more information.) 

Subsequently I 'translated' each of these objectives in *Schematron* rules. For a basic *how-to* see the  [*veraPDF Policy Checking* documentation](http://docs.verapdf.org/policy/). 

The full *Schematron* file can be found [here](https://github.com/KBNLresearch/pdfPolicyVeraPDF/blob/master/schemas/demo-policy.sch).

## VeraPDF configuration

It is important to note that, unlike in my earlier *Apache Preflight* experiments, the *Schematron* rules do not rely on the *PDF/A* validation output! Instead, *VeraPDF* can be instructed to include a 'Features Report' in its output, which directly points to technical features such as font properties, annotation types, security features, and so on. Most of the features that are needed for a policy-based assessment are disabled by default. So, we first need to activate these in the configuration (file *features.xml* in *VeraPDF*'s *config* directory). I edited it as below:

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

## Basic operation

Supposing that the *PDF*s we want to analyze are in directory `~/myPdfs`, and that the *Schematron* rules that represent our policy are in the file `demo-policy.sch`, we can do a policy-based validation of all these files with one single command:  

    verapdf -x --policyfile demo-policy.sch ~/myPdfs/* > myPdfsOut.xml

The output file `myPdfsOut.xml` will then contain, for each *PDF*, an element with *PDF/A* validation output, an element with the features report, and an element with the policy report.

## Analysis script

In many cases the *VeraPDF* output is rather unwieldy. To facilitate things I wrote a [custom analysis script](https://github.com/KBNLresearch/pdfPolicyVeraPDF), which does the following things:

1. Run *VeraPDF*
2. Create a trimmed-down version of the output file that only contains the policy report. Also, for each PDF, duplicate instances of failed (policy) checks are removed (e.g. if a check on font embedding fails for 10 different fonts, only one reference to the failed check is kept)
3. Create a comma-delimited summary file which lists for each PDF its path/name, followed by the description of each unique failed validation rule (taken from the *message* element in *VeraPDF*'s output).

## Running the analysis

Command-line for *fonts* files: 

    ~/pdfPolicyVeraPDF/policyValidate.sh /home/johan/pdfAcrobatEngineering/fonts /home/johan/pdfPolicyVeraPDF/schemas/demo-policy.sch fonts
    
Command-line for *multimedia* files:
    
    ~/pdfPolicyVeraPDF/policyValidate.sh /home/johan/pdfAcrobatEngineering/multimedia /home/johan/pdfPolicyVeraPDF/schemas/demo-policy.sch multimedia
    
## Fonts

(Second column: text in *assert* element of Schematron file). 

|Test file|Failed assert(s)|
|:--|:--|
|EmbeddedCmap.pdf|Font is not embedded|
|embedded_fonts.pdf|Font is not embedded|
|embedded_pm65.pdf||
|notembedded_pm65.pdf|Font is not embedded|
|printtestfont_nonopt.pdf||
|printtestfont_opt.pdf||
|substitution_fonts.pdf|Font is not embedded|
|text_images_pdf1.2.pdf|Font is not embedded|
|TEXT.pdf|Font is not embedded|
|Type3_WWW-HTML.PDF|Font is not embedded|

## Multimedia

|Test file|Failed assert(s)|
|:--|:--|
|20020402_CALOS.pdf|Font is not embedded;Movie annotation|
|3-D_PDF.pdf|3D annotation|
|AdobeChassisDemo-commented.pdf|3D annotation|
|AdobeChassisDemo-commented_Review.pdf|3D annotation|
|AVI+Transitions Demo.pdf|Document not parsable|
|Binder_6-3DPages.pdf|3D annotation|
|Disney-Flash.pdf|Font is not embedded;Screen annotation|
|drape_raster_contour_sample.pdf|Font is not embedded;3D annotation|
|gXsummer2004-stream.pdf|Document not parsable|
|Jpeg_linked.pdf|Encrypted document;Document not parsable|
|LabelExample.pdf|Encrypted document;Document not parsable|
|movie_down1.pdf|Movie annotation|
|movie.pdf|Movie annotation|
|MultiMedia_Acro6.pdf|Encrypted document;Document not parsable|
|MusicalScore.pdf|Font is not embedded;Screen annotation|
|phlmapbeta7.pdf|Font is not embedded;Screen annotation|
|remotemovieurl.pdf|Font is not embedded;Movie annotation|
|ScriptEvents.pdf|Font is not embedded;Screen annotation|
|Service Form_media.pdf|Font is not embedded;Screen annotation|
|SVG-AnnotAnim.pdf|Font is not embedded|
|SVG.pdf|Font is not embedded|
|Trophy.pdf|Font is not embedded;Screen annotation|
|us_population.pdf||

## Issues

* VeraPDF crashed on on one large (49 MB) file
* Feature output does not include *Actions*, which means some potentially interesting features (e.g. JavaScript) cannot be detected.
* Behaviour on encrypted PDFs nor entirely clear. Encounterd some files that can be opened without an Open Password, but which nevertheless throw an exception in VeraPDF:

`Exception: The PDF stream appears to be encrypted. caused by exception: Reader::init(...)encrypted pdf is not supported`


## Links

* This repo
* Report PDF Preservation risks (Zenodo?)
* VeraPDF

 

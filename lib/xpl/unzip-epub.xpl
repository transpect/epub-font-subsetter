<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:tr="http://transpect.io"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:epub2hub = "http://www.le-tex.de/namespace/epub2hub"
  version="1.0"
  name="unzip-epub"
  type="tr:unzip-epub">
   
  <p:documentation>Step to unzip epub and create filelist</p:documentation>
  
  
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" select="resolve-uri('debug')" />
  <p:option name="epubfile" required="true"/>
  
  <p:input port="params" kind="parameter" primary="true">
    <p:documentation>Arbitrary parameters that will be passed to the dynamically executed pipeline.</p:documentation>
  </p:input>
 
  <p:output port="result" primary="false" sequence="true">
    <p:pipe port="result" step="filelist"/>
    <p:documentation>filelist </p:documentation>
  </p:output>
  
  <p:output port="zip-manifest" primary="true" sequence="true">
<!--    <p:pipe port="result" step="zip-mani"></p:pipe>-->
    <p:documentation>zip-manifest</p:documentation>
  </p:output>
  
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
    <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

  <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$epubfile"/>
  </tr:file-uri>

  <tr:unzip name="epub-unzip">
    <p:with-option name="zip" select="/*/@os-path" />
    <p:with-option name="dest-dir" select="concat(/*/@os-path, '.tmp')"/>
    <p:with-option name="overwrite" select="'no'" />
    <p:documentation>Unzips the EPUB file.</p:documentation>
  </tr:unzip>
  
  <p:sink/>

  <p:xslt name="unzip">
    <p:input port="source">
      <p:pipe port="result" step="epub-unzip"/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:template match="* |@*">
            <xsl:copy>
              <xsl:apply-templates select="@*, node()"/>
            </xsl:copy>
          </xsl:template>
          <xsl:template match="@name">
            <xsl:attribute name="name" select="replace(replace(., '\[', '%5B'), '\]', '%5D')"/>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <p:sink/>

  <p:load name="container">
    <p:with-option name="href" select="concat(/c:files/@xml:base, 'META-INF/container.xml')">
      <p:pipe port="result" step="unzip"/>
    </p:with-option>
    <p:documentation>Loads container.xml as point of entry.</p:documentation>
  </p:load>

  <p:sink/>

  <p:xslt name="rootfile">
    <p:documentation>XSL that provides the rootfile's uri.</p:documentation>
    <p:input port="source">
      <p:pipe port="result" step="container"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:param name="base-dir-uri"/>
          <xsl:template match="*:container">
            <c:rootfile>
              <xsl:value-of select="concat($base-dir-uri, *:rootfiles/*:rootfile[1]/@full-path)"/>
            </c:rootfile>
            <xsl:if test="count(*:rootfiles/*:rootfile) eq 0">
              <xsl:message select="'epub2hub WARNING: No rootfile element found in container.xml.'"/>
            </xsl:if>
            <xsl:if test="count(*:rootfiles/*:rootfile) gt 1">
              <xsl:message select="'epub2hub WARNING: More than one rootfile element found in container.xml.'"/>
            </xsl:if>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
    <p:with-param name="base-dir-uri" select="/c:files/@xml:base">
      <p:pipe port="result" step="unzip"/>
    </p:with-param>
  </p:xslt>
  
  <tr:store-debug pipeline-step="epub2hub/rootfile" extension="xml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>
  
  <p:load name="load-rootfile">
    <p:with-option name="href" select="/c:rootfile">
      <p:pipe port="result" step="rootfile"/>
    </p:with-option>
  </p:load>

  <p:sink/>

  <p:xslt name="filelist">
    <p:input port="source">
      <p:pipe port="result" step="load-rootfile"/>
      <p:pipe port="result" step="unzip"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../../epub2hub-lib/xsl/get-filenames-from-spine.xsl">
        <p:documentation>XSL that provides a list of CSS and HTML files in correct order. The order results from the spine element in the rootfile declared in container.xml.</p:documentation>
      </p:document>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:documentation>See step "load-stylesheet".</p:documentation>
  </p:xslt>
  
  <tr:store-debug pipeline-step="epub2hub/filelist">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
<!--  <p:sink/>-->

</p:declare-step>
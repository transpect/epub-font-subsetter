<?xml version="1.0" encoding="utf-8"?>
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
  name="epub-fontsubset"
  type="tr:epub-fontsubset"
  >
  
  <p:documentation>This pipeline can be used to create fontsubsets from an epub.</p:documentation>
  
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" select="resolve-uri('debug')" />
  <p:option name="epubfile" required="true"/>
  
  <p:option name="font-name" required="false"/>
  <p:option name="font-style" required="false" select="'normal'"/>
  <p:option name="font-weight" required="false" select="'normal'"/>
  
  <p:option name="delete-not-used-font" required="false" select="'true'"/>
   
  <p:output port="result" primary="false" sequence="true">
    <p:documentation>Ouput </p:documentation>
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false" indent="true"/>
  
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/css-tools/xpl/css.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/fontsubsetter/xpl/fontsubsetter.xpl"/>
  <p:import href="http://transpect.io/fontsubsetter/xpl/unzip-epub.xpl"/>
  <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>
  <p:import href="http://transpect.io/xproc-util/zip/xpl/zip.xpl"/>
  
  
  <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$epubfile"/>
  </tr:file-uri>
  
  <tr:unzip-epub name="unzipping">
    <p:input port="params">
      <p:empty/>
    </p:input>
    <p:with-option name="epubfile" select="$epubfile"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:unzip-epub>  
  
  <p:sink/>
  
  <p:for-each name="load-html-files" cx:depends-on="unzipping">
    <p:iteration-source select="//file[@type='xhtml']">
      <p:pipe port="result" step="unzipping"/>
    </p:iteration-source>
    
    <p:variable name="base-name" select="/file/@name"/>
    <p:variable name="base-dir" select="//@xml:base">
      <p:pipe port="result" step="unzipping"/>
    </p:variable>
    
    <p:load name="load-html">
      <p:with-option name="href" select="concat($base-dir,$base-name)"/>
      <p:with-option name="dtd-validate" select="false()"/>
    </p:load>
  
    <p:add-xml-base name="add-xml-base"/>
    
    <tr:store-debug name="store1">  
      <p:with-option name="pipeline-step" select="concat('epub2hub/',$base-name)"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

  </p:for-each>
  
  <p:wrap-sequence name="wrap" wrapper="html" wrapper-namespace="http://www.w3.org/1999/xhtml"/>
  
  <p:xslt name="combine-html" cx:depends-on="wrap">
    
    <p:input port="parameters">
      <p:empty/>
    </p:input>
   <p:input port="stylesheet">
     <p:inline>
       <xsl:stylesheet
        xmlns="http://www.w3.org/1999/xhtml"
        xmlns:html="http://www.w3.org/1999/xhtml"
        version="2.0"
        exclude-result-prefixes="#all">
        
        <xsl:variable name="html-head">
           <xsl:apply-templates select="//*:head[1]/node()"/>
        </xsl:variable>
         
         <xsl:variable name="distinct-html-head">
           <xsl:for-each-group select="$html-head//*" group-by="local-name()">
             <xsl:variable name="current-atts" select="distinct-values(current-group()/@*)"/>
             <xsl:variable name="attribut-set" select="current-group()/@*"/>
             
             <xsl:choose>
               <xsl:when test="current-grouping-key() = 'title'">
                 <xsl:sequence select="current-group()[1]"/>
               </xsl:when>
                <xsl:when test="current-grouping-key() = 'meta'">
                 <xsl:for-each-group select="current-group()" group-by="@name">
                  <xsl:sequence select="current-group()[1]"/>
                 </xsl:for-each-group>
               </xsl:when>
               <xsl:when test="current-grouping-key() = 'link'">
                 <xsl:for-each-group select="current-group()" group-by="@href">
                  <xsl:sequence select="current-group()[1]"/>
                 </xsl:for-each-group>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:sequence select="current-group()"/>
               </xsl:otherwise>
             </xsl:choose>        
           
           </xsl:for-each-group>
         </xsl:variable>
        
        <xsl:template match="/*:html">
          <xsl:copy>
            <head>
              <xsl:sequence select="$distinct-html-head"/>
             </head>
            <body>
              <xsl:apply-templates/>
            </body>
          </xsl:copy>
        </xsl:template>
         
         <xsl:template match="*:link">
           <xsl:copy>
             <xsl:apply-templates select="@* except @href"/>
             <xsl:variable name="href" select="replace(@href, '.*(styles/.*)','$1')"/>
<!--             <xsl:message select="$href, ancestor::*:html[1]/@xml:base"/>-->
             <xsl:attribute name="href" select="concat(replace(ancestor::*:html[1]/@xml:base,'(.*OEBPS/).*','$1'), $href)"/>
           </xsl:copy>
         </xsl:template>
        <xsl:template match="*:html[ancestor::*:html]">
            <xsl:apply-templates/>
        </xsl:template>  
        
        <xsl:template match="*:head"/>
          
        <xsl:template match="*:body">
          <div>
            <xsl:attribute name="xml:base" select="ancestor::*:html[1]/@xml:base"/>
            <xsl:apply-templates select="@*, node()"/>
          </div>
        </xsl:template>
          
         <xsl:template match="@*|*" exclude-result-prefixes="#all">
           <xsl:copy copy-namespaces="no">
             <xsl:apply-templates select="@*, node()"/>
           </xsl:copy>
         </xsl:template>
         
       </xsl:stylesheet>
     </p:inline>
   </p:input>
  </p:xslt>
  
    <tr:store-debug name="store2">  
      <p:with-option name="pipeline-step" select="'combined.xhtml'"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
  
  <tr:create-font-subset name="subset" cx:depends-on="combine-html">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:create-font-subset>
  
  <p:wrap-sequence wrapper="out"/>
  
   <cx:message>
      <p:with-option name="message" select="'FONT SUBSETTER', /*:out"/>
    </cx:message>
  
  <p:sink/>
  
    <tr:recursive-directory-list name="zip-manifest"  cx:depends-on="subset">
      <p:with-option name="path" select="replace(//@xml:base,'(.*)/$','$1')">
        <p:pipe port="zip-manifest" step="unzipping"/>
      </p:with-option>
    </tr:recursive-directory-list>
    
    <tr:store-debug pipeline-step="epub2hub/directory-list">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
    
    <!--  delete not-subsetted fonts from file list, if they had been subsetted,
      delete also not-subsetted font, if no subset of them exists, assumption: these fonts are 
      not used in the epub. You can enable this handling by setting the delete-not-used-font option to 'true' -->
    <p:choose>
      <p:when test="$delete-not-used-font = 'true'">
        <p:delete match="c:directory[@name='font']/c:file[not(matches(@name, '.subset$'))][not(following-sibling::*[1]
                                                                                          [self::c:file[matches(@name, 'subset$')]]/@name)]"/>
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>
    
  <p:delete name="change-subset-names" 
      match="c:directory[@name='font']/c:file[following-sibling::*[1]
                                                                  [self::c:file[matches(@name, 'subset$')]]/@name]
                                              [starts-with(following-sibling::*[1][self::c:file[matches(@name, 'subset$')]]/@name, @name)]"/>
    
    
    <p:xslt name="directory-list2manifest" cx:depends-on="change-subset-names">
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet xmlns:c="http://www.w3.org/ns/xproc-step" version="2.0" exclude-result-prefixes="#all">
            <xsl:template match="/">
              <c:zip-manifest>
                <xsl:apply-templates/>
              </c:zip-manifest>
            </xsl:template>
            
            <xsl:template match="c:file">
              <xsl:variable name="name" 
                           select="if (matches(@name, 'mimetype')) 
                                   then @name 
                                   else concat(string-join(ancestor::*[ancestor::*][self::c:directory]/@name,'/'), '/', replace(@name,'.subset',''))"/>
              <c:entry name="{$name}" href="{concat(parent::c:directory/@xml:base, @name)}" compression-method="{if(matches($name, 'mimetype')) then 'stored' else 'deflate'}" compression-level="{if(matches($name, 'mimetype')) then 'none' else 'smallest'}"/>
            </xsl:template>
            
          </xsl:stylesheet>
        </p:inline>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
    </p:xslt>
    
    <tr:store-debug name="store3">  
      <p:with-option name="pipeline-step" select="'zipmanifest'"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
    
    <tr:zip name="zip-new-epub" cx:depends-on="directory-list2manifest">
      <p:with-option name="href" select="concat(replace(//@xml:base,'^(.*)/(.*)/$','$1/'), 'subsetted_',replace($epubfile,'.*/',''))">
        <p:pipe port="result" step="unzipping"/>
      </p:with-option>
    </tr:zip> 
  
<!--  epub:zip-->
  <!--<epub:zip-package name="zip-package">
    <p:input port="ocf-filerefs">
      <p:pipe port="files" step="create-ocf"/>
    </p:input>
    <p:input port="ops-filerefs">
      <p:pipe port="result" step="conditionally-remove-nav-from-filelist-if-epub2"/>
    </p:input>
    <p:input port="opf-fileref">
      <p:pipe port="files" step="create-opf"/>
    </p:input>
    <p:input port="meta">
      <p:pipe port="meta" step="epub-convert"/>
    </p:input>
    <p:with-option name="base-uri" select="/c:result/@local-href">
      <p:pipe port="result" step="base-uri"/>
    </p:with-option>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="replace($debug-dir-uri, '^(.+)\?.*$', '$1')"><p:empty/></p:with-option>
  </epub:zip-package>-->

</p:declare-step>

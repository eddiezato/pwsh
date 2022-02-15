<xsl:stylesheet version="1.0"
                xmlns="http://www.daisy.org/z3986/2005/ncx/"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:fb="http://www.gribuser.ru/xml/fictionbook/2.0">
    <xsl:output method="xml" encoding="UTF-8"/>
    <xsl:param name="src-name" select="'index.xhtml'"/>
    <xsl:param name="tocdepth" select="3"/>
    <xsl:param name="toccut" select="1"/>
    <xsl:key name="note-link" match="fb:section" use="@id"/>
    <xsl:template match="/*">
        <!--<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">-->
        <ncx version="2005-1">
        <head>
            <xsl:element name="meta">
                <xsl:attribute name="name">dtb:uid</xsl:attribute>
                <xsl:choose>
                    <xsl:when test="//fb:description/fb:document-info/fb:id and //fb:description/fb:document-info/fb:id != ''">
                        <xsl:attribute name="content"><xsl:value-of select="//fb:description/fb:document-info/fb:id"/></xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="content">123456789X</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
            <meta name="dtb:depth" content="2"/>
            <meta name="dtb:totalPageCount" content="0"/>
            <meta name="dtb:maxPageNumber" content="0"/>
        </head>
        <docTitle><text>
            <xsl:value-of select="fb:description/fb:title-info/fb:book-title"/>
        </text></docTitle>
        <docAuthor><text>
            <xsl:value-of select="fb:last-name"/><xsl:text>&#32;</xsl:text>
            <xsl:value-of select="fb:first-name"/><xsl:text>&#32;</xsl:text>
            <xsl:value-of select="fb:middle-name"/>
        </text></docAuthor>

        <!-- BUILD navMap -->
        <navMap>
            <navPoint class="toc" id="toc">
                <navLabel><text>Table of Contents</text></navLabel>
                <content src="{$src-name}#TOC"/>
            </navPoint>
            <xsl:if test="$tocdepth &gt; 0 and count(//fb:body[not(@name) or @name != 'notes']//fb:title) &gt; 1">
                <xsl:apply-templates select="fb:body" mode="toc"/>
            </xsl:if>
        </navMap>

    </ncx>
    </xsl:template>
    <!-- toc template: body -->
    <xsl:template match="fb:body" mode="toc">
        <xsl:choose>
            <xsl:when test="@name = 'notes'"><br/>
                <navPoint class="toc" id="TOC_notes">
                    <navLabel><text>Notes</text></navLabel>
                    <content src="{$src-name}#TOC_notes"/>
                </navPoint>
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates mode="toc" select="fb:section"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- toc template: section -->
    <xsl:template match="fb:section" mode="toc">
       <xsl:if test="fb:title | .//fb:section[count(ancestor::fb:section) &lt; $tocdepth - 1]/fb:title">
           <xsl:apply-templates select="fb:title" mode="toc"/>
           <xsl:if test="(.//fb:section/fb:title) and (count(ancestor::fb:section) &lt; $tocdepth - 1 or $tocdepth=    999)">
                <xsl:apply-templates select="fb:section" mode="toc"/>
            </xsl:if>
       </xsl:if>
    </xsl:template>

    <!-- toc template: title -->
    <xsl:template match="fb:title" mode="toc">
        <navPoint class="toc" id="{generate-id()}">
            <navLabel>
                <text>
                    <xsl:choose>
                        <xsl:when test="$toccut &gt; 0">
                            <xsl:value-of select="normalize-space(fb:p[1])"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="fb:title/fb:p">
                                <xsl:if test="position()>1"><xsl:text> </xsl:text></xsl:if>
                                <xsl:value-of select="normalize-space(.)"/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </text>
            </navLabel>
            <content src="{$src-name}#TOC_{generate-id()}"/>
        </navPoint>
    </xsl:template>
</xsl:stylesheet>

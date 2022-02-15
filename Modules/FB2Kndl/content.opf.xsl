<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns="http://www.idpf.org/2007/opf"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:fb="http://www.gribuser.ru/xml/fictionbook/2.0"
                xmlns:xlink="http://www.w3.org/1999/xlink" >
    <xsl:output encoding="UTF-8" method="xml"/>
    <xsl:param name="src-name" select="'index.xhtml'"/>
    <xsl:param name="ncx-name" select="'toc.ncx'"/>
    <xsl:variable name="CoverID">
        <xsl:choose>
            <xsl:when test="starts-with(//fb:title-info/fb:coverpage/fb:image[1]/@xlink:href,'#')">
                <xsl:value-of select="substring-after(//fb:title-info/fb:coverpage/fb:image[1]/@xlink:href,'#')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="//fb:title-info/fb:coverpage/fb:image[1]/@xlink:href"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:template match="/*">
        <package version="2.0" unique-identifier="BookId">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
                <dc:title>
                    <xsl:value-of select="//fb:book-title"/>
                </dc:title>
                <xsl:for-each select="//fb:description/fb:title-info/fb:author">
                    <dc:creator opf:file-as="{fb:last-name}, {fb:first-name}" opf:role="aut">
                        <xsl:value-of select="fb:last-name"/><xsl:text>&#32;</xsl:text>
                        <xsl:value-of select="fb:first-name"/><xsl:text>&#32;</xsl:text>
                        <xsl:value-of select="fb:middle-name"/>
                    </dc:creator>
                </xsl:for-each>
                <xsl:if test="//fb:description/fb:title-info/fb:date/@value">
                    <dc:date>
                        <xsl:value-of select="//fb:description/fb:title-info/fb:date/@value"/>
                    </dc:date>
                </xsl:if>
                <dc:subject>
                    <xsl:value-of select="//fb:description/fb:title-info/fb:genre"/>
                </dc:subject>
                <dc:identifier id="BookId">
                    <xsl:choose>
                        <xsl:when test="//fb:description/fb:document-info/fb:id and //fb:description/fb:document-info/fb:id != ''">
                            <xsl:value-of select="//fb:description/fb:document-info/fb:id"/>
                        </xsl:when>
                        <xsl:otherwise>123456789X</xsl:otherwise>
                    </xsl:choose>
                </dc:identifier>
                <dc:language>
                    <xsl:choose>
                        <xsl:when test="//fb:description/fb:title-info/fb:lang">
                            <xsl:value-of select="//fb:description/fb:title-info/fb:lang"/>
                        </xsl:when>
                        <xsl:otherwise>ru</xsl:otherwise>
                    </xsl:choose>
                </dc:language>
                <xsl:if test="//fb:description/fb:title-info/fb:annotation">
                    <dc:description><xsl:value-of select="//fb:description/fb:title-info/fb:annotation"/></dc:description>
                </xsl:if>
                <xsl:if test="//description/publish-info/publisher">
                    <dc:publisher><xsl:value-of select="//fb:description/fb:publish-info/fb:publisher"/></dc:publisher>
                </xsl:if>
                <meta name="output encoding" content="utf-8" />
                <meta name="cover" content="{$CoverID}" />
            </metadata>
            <manifest>
                <item id="content" href="{$src-name}" media-type="application/xhtml+xml"/>
                <item id="stylesheet" href="styles.css" media-type="text/css"/>
                <xsl:apply-templates select="//fb:binary" />
                <item id="ncx" href="{$ncx-name}" media-type="application/x-dtbncx+xml"/>
            </manifest>
          <spine toc="ncx">
                <itemref idref="content" xmlns="http://www.idpf.org/2007/opf"/>
          </spine>
          <xsl:if test="(count(//fb:body[not(@name) or @name != 'notes']//fb:title) &gt; 1) and //fb:title-info/fb:coverpage/fb:image">
                <guide>
                    <reference type="text" title="Text" href="{$src-name}" />
                    <xsl:if test="count(//fb:body[not(@name) or @name != 'notes']//fb:title) &gt; 1">
                        <reference type="toc" title="Table of Contents" href="{$src-name}#TOC" />
                    </xsl:if>
                    <xsl:if test="//fb:title-info/fb:coverpage/fb:image">
                        <reference type="cover" title="Cover" href="{$CoverID}"/>
                    </xsl:if>
                </guide>
            </xsl:if>
        </package>
    </xsl:template>
    <xsl:template match="fb:binary">
        <xsl:choose>
            <xsl:when test="@id=$CoverID"><item id="cover" href="{@id}" media-type="{@content-type}"/></xsl:when>
            <xsl:otherwise><item id="{@id}" href="{@id}" media-type="{@content-type}"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>

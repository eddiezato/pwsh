<xsl:stylesheet version="1.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:fb="http://www.gribuser.ru/xml/fictionbook/2.0">
    <xsl:param name="tocdepth" select="3"/>
    <xsl:param name="toccut" select="1"/>
    <xsl:param name="addimage" select="0"/>
    <xsl:key name="note-link" match="fb:section" use="@id"/>
    <xsl:output method="xml" encoding="UTF-8"/>

    <xsl:template match="/*">
        <html>
            <head>
                <title><xsl:value-of select="fb:description/fb:title-info/fb:book-title"/></title>
                <link rel="stylesheet" type="text/css" href="styles.css" />
            </head>
            <body>
                <xsl:if test="$addimage &gt; 0">
                    <xsl:apply-templates select="fb:description/fb:title-info/fb:coverpage/fb:image"/>
                </xsl:if>
                <!-- add annotation -->
                <xsl:for-each select="fb:description/fb:title-info/fb:annotation">
                    <div><xsl:call-template name="annotation"/></div>
                    <hr/>
                </xsl:for-each>
                <!-- build TOC -->
                <div id="TOC">
                    <xsl:if test="$tocdepth &gt; 0 and count(//fb:body[not(@name) or @name != 'notes']//fb:title) &gt; 1">
                        <ul><xsl:apply-templates select="fb:body" mode="toc"/></ul>
                    </xsl:if>
                </div>
                <!-- build book -->
                <xsl:for-each select="fb:body">
                    <xsl:if test="position()!=1"><hr/></xsl:if>
                    <xsl:if test="@name = 'notes' and not(fb:title)">
                        <h1 id="TOC_notes">Notes</h1>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:for-each>
            </body>
        </html>
    </xsl:template>

    <!-- toc template: body -->
    <xsl:template match="fb:body" mode="toc">
        <xsl:choose>
            <xsl:when test="@name = 'notes'"><br/><li><a href="#TOC_notes">Notes</a></li></xsl:when>
            <xsl:otherwise><xsl:apply-templates mode="toc" select="fb:section"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- toc template: section -->
    <xsl:template match="fb:section" mode="toc">
        <xsl:if test="fb:title | .//fb:section[count(ancestor::fb:section) &lt; $tocdepth - 1]/fb:title">
            <li>
                <xsl:apply-templates select="fb:title" mode="toc"/>
                <xsl:if test="(.//fb:section/fb:title) and (count(ancestor::fb:section) &lt; $tocdepth - 1 or $tocdepth=    999)">
                    <ul><xsl:apply-templates select="fb:section" mode="toc"/></ul>
                </xsl:if>
            </li>
        </xsl:if>
    </xsl:template>

    <!-- toc template: title -->
    <xsl:template match="fb:title" mode="toc">
        <a href="#TOC_{generate-id()}">
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
        </a>
    </xsl:template>

    <!-- description -->
    <xsl:template match="fb:description">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- section -->
    <xsl:template match="fb:section">
        <xsl:apply-templates select="fb:title"/>
        <div><xsl:apply-templates select="fb:*[name()!='title']"/></div>
    </xsl:template>

    <!-- title -->
    <xsl:template match="fb:section/fb:title|fb:poem/fb:title">
        <xsl:choose>
            <xsl:when test="ancestor::fb:body/@name = 'notes' and not(following-sibling::fb:section)">
                <xsl:for-each select="parent::fb:section">
                    <xsl:call-template name="preexisting_id"/>
                </xsl:for-each>
                <strong><xsl:apply-templates/></strong>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="count(ancestor::node()) &lt; 9">
                        <xsl:element name="{concat('h',count(ancestor::node())-3)}">
                            <xsl:attribute name="id">TOC_<xsl:value-of select="generate-id()"/></xsl:attribute>
                            <xsl:attribute name="align">center</xsl:attribute>
                            <xsl:apply-templates/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="h6">
                            <xsl:call-template name="preexisting_id"/>
                            <xsl:apply-templates/>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- body/title -->
    <xsl:template match="fb:body/fb:title">
        <h1>
            <xsl:if test="ancestor::fb:body/@name = 'notes'">
                <xsl:attribute name="id">TOC_notes</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </h1>
    </xsl:template>

    <!-- title/p and the like -->
    <xsl:template match="fb:title/fb:p|fb:title-info/fb:book-title">
        <xsl:apply-templates/><br/>
    </xsl:template>

    <!-- subtitle -->
    <xsl:template match="fb:subtitle">
        <h5><xsl:apply-templates/></h5>
    </xsl:template>

    <!-- p -->
    <xsl:template match="fb:p">
        <div class="paragraph"><xsl:apply-templates/></div>
    </xsl:template>

    <!-- strong -->
    <xsl:template match="fb:strong">
        <b><xsl:apply-templates/></b>
    </xsl:template>

    <!-- emphasis -->
    <xsl:template match="fb:emphasis">
        <i><xsl:apply-templates/></i>
    </xsl:template>

    <!-- code -->
    <xsl:template match="fb:code">
        <code><xsl:apply-templates/></code>
    </xsl:template>
    
    <!-- Strikethrough text -->
    <xsl:template match="fb:strikethrough">
        <del><xsl:apply-templates/></del>
    </xsl:template>

    <!-- super/sub-scripts -->
    <xsl:template match="fb:sup">
        <sup><xsl:apply-templates/></sup>
    </xsl:template>
    <xsl:template match="fb:sub">
        <sub><xsl:apply-templates/></sub>
    </xsl:template>

    <!-- style -->
    <xsl:template match="fb:style">
        <span class="{@name}"><xsl:apply-templates/></span>
    </xsl:template>

    <!-- empty-line -->
    <xsl:template match="fb:empty-line">
        &#160;<br/>
    </xsl:template>

    <!-- link -->
    <xsl:template match="fb:a">
        <xsl:element name="a">
            <xsl:attribute name="href"><xsl:value-of select="@xlink:href"/></xsl:attribute>
            <xsl:attribute name="title">
                <xsl:choose>
                    <xsl:when test="starts-with(@xlink:href,'#')"><xsl:value-of select="key('note-link',substring-after(@xlink:href,'#'))/fb:p"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="key('note-link',@xlink:href)/fb:p"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="(@type) = 'note'">
                    <sup><xsl:apply-templates/></sup>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- annotation -->
    <xsl:template name="annotation">
        <h3>Annotation</h3>
        <xsl:apply-templates/>
    </xsl:template>

    <!-- epigraph -->
    <xsl:template match="fb:epigraph">
        <blockquote class="epigraph">
            <xsl:apply-templates/>
        </blockquote>
        <xsl:if test="name(./following-sibling::node()) = 'epigraph'"><br/></xsl:if>
        <br/>
    </xsl:template>

    <!-- epigraph/text-author -->
    <xsl:template match="fb:epigraph/fb:text-author">
        <blockquote>
            <b><i><xsl:apply-templates/></i></b>
        </blockquote>
    </xsl:template>

    <!-- cite -->
    <xsl:template match="fb:cite">
        <blockquote>
        <xsl:apply-templates/>
        </blockquote>
    </xsl:template>

    <!-- cite/text-author -->
    <xsl:template match="fb:text-author">
        <blockquote><i><xsl:apply-templates/></i></blockquote>
    </xsl:template>

    <!-- date -->
    <xsl:template match="fb:date">
        <xsl:choose>
            <xsl:when test="not(@value)">
                &#160;&#160;&#160;<xsl:apply-templates/>
                <br/>
            </xsl:when>
            <xsl:otherwise>
                &#160;&#160;&#160;<xsl:value-of select="@value"/>
                <br/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- poem -->
    <xsl:template match="fb:poem">
        <blockquote>
            <xsl:apply-templates/>
        </blockquote>
    </xsl:template>

    <!-- stanza -->
    <xsl:template match="fb:stanza">
        &#160;<br/>
        <xsl:apply-templates/>
        &#160;<br/>
    </xsl:template>

    <!-- tables -->
    <xsl:template match="fb:table">
        <table><xsl:apply-templates/></table>
    </xsl:template>

    <!-- v -->
    <xsl:template match="fb:v">
        <xsl:apply-templates/><br/>
    </xsl:template>

    <!-- image - inline -->
    <xsl:template match="fb:p/fb:image|fb:v/fb:image|fb:td/fb:image|fb:subtitle/fb:image">
        <img>
            <xsl:choose>
                <xsl:when test="starts-with(@xlink:href,'#')">
                    <xsl:attribute name="src"><xsl:value-of select="substring-after(@xlink:href,'#')"/></xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="src"><xsl:value-of select="@xlink:href"/></xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </img>
    </xsl:template>

    <!-- image - block -->
    <xsl:template match="fb:image">
        <xsl:element name="div">
            <xsl:if test="ancestor::fb:coverpage">
                <xsl:attribute name="class">coverpage</xsl:attribute>
            </xsl:if>
            <xsl:attribute name="align">center</xsl:attribute>
            <xsl:element name="img">
                <xsl:choose>
                    <xsl:when test="starts-with(@xlink:href,'#')">
                        <xsl:attribute name="src"><xsl:value-of select="substring-after(@xlink:href,'#')"/></xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="src"><xsl:value-of select="@xlink:href"/></xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="@title">
                    <xsl:attribute name="title"><xsl:value-of select="@title"/></xsl:attribute>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- we preserve used ID's and drop unused ones -->
    <xsl:template name="preexisting_id">
        <xsl:variable name="i" select="@id"/>
        <xsl:if test="@id and //fb:a[@xlink:href=concat('#',$i)]">
            <a id="{@id}"/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
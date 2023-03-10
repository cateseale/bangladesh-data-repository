<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <!--This script takes as input document a master QGIS template, and references a CSV with names and positions of elements in an ArcGIS template-->
    <!-- It also requires https://github.com/mapaction/mapaction-toolbox/blob/master/arcgis10_mapping_tools/MapAction/MapAction/Resources/language_config.xml to generate templates in a number of languages  -->
    <!--It uses this to generated a set of standard QGIS templates, populating them with the correct values-->
    <!--Ant Scott, MapAction July 2020-->

    <xsl:output method="xml" encoding="utf-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <!--The file name of the element values document, containing positions and heights of all layout elements-->
    <xsl:variable name="v_values-doc" select="'template_positions.txt'"/>

    <!--The file name of the language values, containing translations of labels-->
    <xsl:variable name="v_lang-doc" select="document('language_config.xml')"/>

    <!-- The file name of the QGIS master template-->
    <xsl:variable name="v_template-master" select="'ma_qgis_master_v1.qpt'"/>

    <!--The prefix for the Arc version used in the element values document
    <xsl:variable name="v_arc-version" select="'arcmap-10.6_'"/>-->

    <!--Create a key to hold labels for every item/language combination-->
    <!-- removed map_producer | for now--> 
    <xsl:key name="k_lang"
        match="create_date_time_label | data_sources_label | spatial_reference_label | glide_no_label | donor_credit | disclaimer"
        use="concat(local-name(), parent::language/@name)"/>

    <xsl:template match="/">
        <!--Create a template set for each language specified in the languages doc-->

        <xsl:for-each select="$v_lang-doc/languageSettings/language/@name">
            <!--Process the master template doc once for each template and language-->
            <!--This could be made generic to pick up all template values-->
            <xsl:apply-templates select="document($v_template-master)" mode="m_templates">
                <xsl:with-param name="p_template-name">
                    <xsl:value-of select="'reference-landscape-bottom'"/>
                </xsl:with-param>
                <xsl:with-param name="p_language">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="document($v_template-master)" mode="m_templates">
                <xsl:with-param name="p_template-name">
                    <xsl:value-of select="'reference-landscape-side'"/>
                </xsl:with-param>
                <xsl:with-param name="p_language">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="document($v_template-master)" mode="m_templates">
                <xsl:with-param name="p_template-name">
                    <xsl:value-of select="'reference-portrait-bottom'"/>
                </xsl:with-param>
                <xsl:with-param name="p_language">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="document($v_template-master)" mode="m_templates">
                <xsl:with-param name="p_template-name">
                    <xsl:value-of select="'thematic-landscape'"/>
                </xsl:with-param>
                <xsl:with-param name="p_language">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="document($v_template-master)" mode="m_templates">
                <xsl:with-param name="p_template-name">
                    <xsl:value-of select="'thematic-portrait'"/>
                </xsl:with-param>
                <xsl:with-param name="p_language">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <!--Create a new template file for each type/language-->
    <xsl:template match="/Layout" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <!--Create QGIS template based on source template name and language-->
        <xsl:result-document
            href="{concat('qgis_3_',$p_template-name,'_',lower-case($p_language),'.qpt')}">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="m_templates">
                    <xsl:with-param name="p_template-name" select="$p_template-name"/>
                    <xsl:with-param name="p_language" select="$p_language"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>

    <!-- Change the name of the template to a qgis version with language-->
    <xsl:template match="/Layout/@name" mode="m_templates">
        <xsl:param name="p_language"/>
        <xsl:param name="p_template-name"/>
        <xsl:attribute name="name">
            <xsl:value-of
                select="concat('qgis_3_',$p_template-name,'_', lower-case($p_language))"
            />
        </xsl:attribute>
    </xsl:template>

    <!-- Change the paper size depending on portrait or landscape -->
    <xsl:template match="/Layout/PageCollection/LayoutItem/@size" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:choose>
            <xsl:when test="contains($p_template-name, 'portrait')">
                <xsl:attribute name="size">
                    <xsl:value-of select="'297,420,mm'"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="size">
                    <xsl:value-of select="'420,297,mm'"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Set label text values according to language -->
    <xsl:template match="/Layout/LayoutItem/@labelText" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:choose>
            <xsl:when test="key('k_lang', concat(parent::LayoutItem/@id, $p_language), $v_lang-doc)">
                <xsl:attribute name="labelText">
                    <xsl:value-of
                        select="key('k_lang', concat(parent::LayoutItem/@id, $p_language), $v_lang-doc)/normalize-space(.)"
                    />
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="labelText">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Set position for each item-->
    <xsl:template match="/Layout/LayoutItem/@position | /Layout/LayoutItem/@positionOnPage"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="parent::LayoutItem/@id"/>
        <xsl:variable name="v_reference-point" select="../@referencePoint"/>
        <xsl:variable name="v_item-exists">
            
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:attribute name="{$v_attribute}">
                    <xsl:call-template name="t_get_xy">
                        <xsl:with-param name="p_element" select="$v_id"/>
                        <xsl:with-param name="p_template-name" select="$p_template-name"/>
                        <xsl:with-param name="p_reference-point" select="$v_reference-point"/>
                    </xsl:call-template>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="{$v_attribute}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Include only items which are in the lookup-->
    <xsl:template match="/Layout/LayoutItem" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="@id"/>
        <xsl:variable name="v_this-item" select="."/>
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m_templates">
                        <xsl:with-param name="p_template-name" select="$p_template-name"/>
                        <xsl:with-param name="p_language" select="$p_language"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

    <!-- Set size for each item-->
    <xsl:template match="/Layout/LayoutItem/@size" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="../@id"/>
        <xsl:variable name="v_value" select="."/>
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="tokenize(., ';')"/>
                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_height" select="normalize-space($v_row[7])"/>
                            <xsl:variable name="v_width" select="normalize-space($v_row[8])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="concat($v_width, ',', $v_height, ',mm')"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Height and Y settings for maps have to be set as data driven, otherwise they are overwritten by extent-->
    <!--Main map height-->
    <xsl:template
        match="/Layout/LayoutItem[@id = ('Main map')]/LayoutObject/dataDefinedProperties/Option[@type = 'Map']/Option[@name = 'properties']/Option[@name = 'dataDefinedHeight']/Option[@name = 'expression']/@value"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="'Main map'"/>
        <!--<xsl:variable name="v_id" select="'Main map'"/>-->
        
        <xsl:variable name="v_value" select="."/>
      <!--  <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-\- When the item exists in the lookup, using the position settings -\->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>-->
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:message>Main Map</xsl:message>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
               
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="tokenize(., ';')"/>
                    <!--<xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>-->
                    
                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_height" select="normalize-space($v_row[7])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="$v_height"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Location map height-->
    <xsl:template
        match="/Layout/LayoutItem[@id = ('Location map')]/LayoutObject/dataDefinedProperties/Option[@type = 'Map']/Option[@name = 'properties']/Option[@name = 'dataDefinedHeight']/Option[@name = 'expression']/@value"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="'Location map'"/>
        <xsl:variable name="v_value" select="."/>
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
    <!--    <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-\- When the item exists in the lookup, using the position settings -\->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>-->
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="tokenize(., ';')"/>

                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_height" select="normalize-space($v_row[7])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="$v_height"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Main map Y-->
    <xsl:template
        match="/Layout/LayoutItem[@id = ('Main map')]/LayoutObject/dataDefinedProperties/Option[@type = 'Map']/Option[@name = 'properties']/Option[@name = 'dataDefinedPositionY']/Option[@name = 'expression']/@value"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_page-height">
            <xsl:choose>
                <xsl:when test="contains($p_template-name, 'portrait')">420</xsl:when>
                <xsl:otherwise>297</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="'Main map Map Frame'"/>
        <xsl:variable name="v_value" select="."/>
   <!--     <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-\- When the item exists in the lookup, using the position settings -\->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>-->
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>

                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_y" select="normalize-space($v_row[6])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="$v_page-height - number($v_y)"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Location map Y-->
    <xsl:template
        match="/Layout/LayoutItem[@id = ('Location map')]/LayoutObject/dataDefinedProperties/Option[@type = 'Map']/Option[@name = 'properties']/Option[@name = 'dataDefinedPositionY']/Option[@name = 'expression']/@value"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_page-height">
            <xsl:choose>
                <xsl:when test="contains($p_template-name, 'portrait')">420</xsl:when>
                <xsl:otherwise>297</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="'Location map'"/>
        <xsl:variable name="v_value" select="."/>
   <!--     <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-\- When the item exists in the lookup, using the position settings -\->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>-->
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="tokenize(., ';')"/>
                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_y" select="normalize-space($v_row[6])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="$v_page-height - number($v_y)"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--Scale height needs to be data driven as height value not accepted-->
    <xsl:template
        match="/Layout/LayoutItem[@id = ('scale')]/LayoutObject/dataDefinedProperties/Option[@type = 'Map']/Option[@name = 'properties']/Option[@name = 'dataDefinedHeight']/Option[@name = 'expression']/@value"
        mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:variable name="v_attribute" select="local-name()"/>
        <xsl:variable name="v_id" select="'scale'"/>
        <xsl:variable name="v_value" select="."/>
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_item-exists">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when
                        test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')"
                        >T</xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_item-exists = 'T'">
                <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                    <xsl:variable name="v_row" select="replace(tokenize(., ';'),'&quot;','')"/>
                    
                    <!-- When the item exists in the lookup, using the position settings -->
                    <xsl:choose>
                        <xsl:when
                            test="$v_row[1] = $p_template-name and $v_row[3] = $v_id and not($v_id = '')">
                            <xsl:variable name="v_height" select="normalize-space($v_row[7])"/>
                            <xsl:attribute name="{$v_attribute}">
                                <xsl:value-of select="$v_height"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$v_value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Calculate xy postions - all anchor points are bottom left-->
    <xsl:template name="t_get_xy">
        <xsl:param name="p_element"/>
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_reference-point"/>
        <xsl:variable name="v_page-height">
            <xsl:choose>
                <xsl:when test="contains($p_template-name, 'portrait')">420</xsl:when>
                <xsl:otherwise>297</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_x">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when test="$v_row[1] = $p_template-name and $v_row[3] = $p_element">
                        <xsl:value-of select="$v_row[5]"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_y">
            <xsl:for-each select="tokenize(unparsed-text($v_values-doc), '\n')">
                <xsl:variable name="v_row" select="tokenize(., ';')"/>
                <!-- When the item exists in the lookup, using the position settings -->
                <xsl:choose>
                    <xsl:when test="$v_row[1] = $p_template-name and $v_row[3] = $p_element">
                        <xsl:value-of select="$v_row[6]"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="concat($v_x, ',', ($v_page-height - $v_y), ',mm')"/>
    </xsl:template>

    <xsl:template match="@* | node()" mode="m_templates">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_templates">
                <xsl:with-param name="p_template-name" select="$p_template-name"/>
                <xsl:with-param name="p_language" select="$p_language"/>

            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <!--    <xsl:template match="@* | node()" mode="m_language">
                <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_language">
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
-->
    <xsl:template match="@* | node()">
        <xsl:param name="p_template-name"/>
        <xsl:param name="p_language"/>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()">
                <xsl:with-param name="p_template-name"/>
                <xsl:with-param name="p_language" select="$p_language"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
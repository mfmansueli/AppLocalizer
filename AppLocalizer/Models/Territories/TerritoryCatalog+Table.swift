//
//  TerritoryCatalog+Table.swift
//  AppLocalizer
//

import Foundation

extension TerritoryCatalog {
    /// Every App Store territory, one per line:
    /// `alpha-3|alpha-2|name|region|currency|tax rate|latitude|longitude`.
    /// Region is A (Americas), E (Europe), P (Asia Pacific) or M (Africa & Middle East).
    /// Tax rates and coordinates are approximate, from the design prototype.
    static let table = """
    USA|US|United States|A|USD|0|39|-98
    CAN|CA|Canada|A|CAD|0.13|56|-106
    MEX|MX|Mexico|A|MXN|0.16|23|-102
    BRA|BR|Brazil|A|BRL|0|-10|-52
    ARG|AR|Argentina|A|USD|0.21|-34|-64
    CHL|CL|Chile|A|CLP|0.19|-33|-71
    COL|CO|Colombia|A|COP|0.19|4|-73
    PER|PE|Peru|A|PEN|0.18|-9|-75
    ECU|EC|Ecuador|A|USD|0.15|-1|-78
    BOL|BO|Bolivia|A|USD|0|-17|-64
    PRY|PY|Paraguay|A|USD|0.1|-23|-58
    URY|UY|Uruguay|A|USD|0.22|-33|-56
    VEN|VE|Venezuela|A|USD|0.16|7|-66
    CRI|CR|Costa Rica|A|USD|0.13|10|-84
    PAN|PA|Panama|A|USD|0.07|9|-80
    GTM|GT|Guatemala|A|USD|0.12|15|-90
    HND|HN|Honduras|A|USD|0.15|15|-87
    SLV|SV|El Salvador|A|USD|0.13|14|-89
    NIC|NI|Nicaragua|A|USD|0.15|13|-85
    DOM|DO|Dominican Republic|A|USD|0.18|19|-70
    JAM|JM|Jamaica|A|USD|0.15|18|-77
    TTO|TT|Trinidad and Tobago|A|USD|0.125|10.5|-61
    BRB|BB|Barbados|A|USD|0.175|13|-59.5
    BHS|BS|Bahamas|A|USD|0.1|24|-77
    BLZ|BZ|Belize|A|USD|0.125|17|-88.5
    ATG|AG|Antigua and Barbuda|A|USD|0.15|17|-61.8
    AIA|AI|Anguilla|A|USD|0|18.2|-63
    BMU|BM|Bermuda|A|USD|0|32|-64.8
    VGB|VG|British Virgin Islands|A|USD|0|18.4|-64.6
    CYM|KY|Cayman Islands|A|USD|0|19.3|-81.3
    DMA|DM|Dominica|A|USD|0.15|15.4|-61.4
    GRD|GD|Grenada|A|USD|0.15|12.1|-61.7
    GUY|GY|Guyana|A|USD|0.14|5|-59
    MSR|MS|Montserrat|A|USD|0|16.7|-62.2
    KNA|KN|St Kitts and Nevis|A|USD|0.17|17.3|-62.7
    LCA|LC|St Lucia|A|USD|0.125|13.9|-61
    VCT|VC|St Vincent and the Grenadines|A|USD|0.16|13.2|-61.2
    SUR|SR|Suriname|A|USD|0.1|4|-56
    TCA|TC|Turks and Caicos Islands|A|USD|0|21.7|-71.8
    AUT|AT|Austria|E|EUR|0.2|47.5|14.5
    BEL|BE|Belgium|E|EUR|0.21|50.6|4.6
    BGR|BG|Bulgaria|E|EUR|0.2|42.7|25.5
    HRV|HR|Croatia|E|EUR|0.25|45.1|15.2
    CYP|CY|Cyprus|E|EUR|0.19|35|33
    EST|EE|Estonia|E|EUR|0.24|58.6|25
    FIN|FI|Finland|E|EUR|0.255|64|26
    FRA|FR|France|E|EUR|0.2|46.6|2.4
    DEU|DE|Germany|E|EUR|0.19|51|10.4
    GRC|GR|Greece|E|EUR|0.24|39|22
    IRL|IE|Ireland|E|EUR|0.23|53.3|-8
    ITA|IT|Italy|E|EUR|0.22|42.8|12.5
    LVA|LV|Latvia|E|EUR|0.21|56.9|24.6
    LTU|LT|Lithuania|E|EUR|0.21|55.2|23.9
    LUX|LU|Luxembourg|E|EUR|0.17|49.8|6.1
    MLT|MT|Malta|E|EUR|0.18|35.9|14.4
    NLD|NL|Netherlands|E|EUR|0.21|52.1|5.3
    PRT|PT|Portugal|E|EUR|0.23|39.6|-8
    SVK|SK|Slovakia|E|EUR|0.23|48.7|19.7
    SVN|SI|Slovenia|E|EUR|0.22|46.1|14.8
    ESP|ES|Spain|E|EUR|0.21|40.4|-3.7
    GBR|GB|United Kingdom|E|GBP|0.2|54|-2
    CHE|CH|Switzerland|E|CHF|0.081|46.8|8.2
    NOR|NO|Norway|E|NOK|0.25|61|9
    SWE|SE|Sweden|E|SEK|0.25|62|15
    DNK|DK|Denmark|E|DKK|0.25|56|10
    POL|PL|Poland|E|PLN|0.23|52|19
    CZE|CZ|Czechia|E|CZK|0.21|49.8|15.5
    HUN|HU|Hungary|E|HUF|0.27|47.2|19.5
    ROU|RO|Romania|E|RON|0.19|45.9|25
    ISL|IS|Iceland|E|USD|0.24|65|-18
    TUR|TR|Türkiye|E|TRY|0.2|39|35
    UKR|UA|Ukraine|E|USD|0.2|49|32
    BLR|BY|Belarus|E|USD|0.2|53.7|28
    MDA|MD|Moldova|E|USD|0.2|47.4|28.4
    SRB|RS|Serbia|E|USD|0.2|44|21
    BIH|BA|Bosnia and Herzegovina|E|USD|0.17|44|17.7
    MKD|MK|North Macedonia|E|USD|0.18|41.6|21.7
    ALB|AL|Albania|E|USD|0.2|41.1|20
    MNE|ME|Montenegro|E|USD|0.21|42.7|19.3
    XKS|XK|Kosovo|E|USD|0.18|42.6|20.9
    ARM|AM|Armenia|E|USD|0.2|40|45
    AZE|AZ|Azerbaijan|E|USD|0.18|40.4|47.6
    GEO|GE|Georgia|E|USD|0.18|42.3|43.4
    KAZ|KZ|Kazakhstan|E|KZT|0.12|48|67
    UZB|UZ|Uzbekistan|E|USD|0.12|41.4|64.6
    KGZ|KG|Kyrgyzstan|E|USD|0.12|41.2|74.8
    TJK|TJ|Tajikistan|E|USD|0.15|38.9|71.3
    TKM|TM|Turkmenistan|E|USD|0.15|38.97|59.6
    JPN|JP|Japan|P|JPY|0.1|36|138
    KOR|KR|South Korea|P|KRW|0.1|36|128
    CHN|CN|China mainland|P|CNY|0.06|35|104
    HKG|HK|Hong Kong|P|HKD|0|22.3|114.2
    TWN|TW|Taiwan|P|TWD|0.05|23.7|121
    SGP|SG|Singapore|P|SGD|0.09|1.35|103.8
    MYS|MY|Malaysia|P|MYR|0.08|4.2|102
    THA|TH|Thailand|P|THB|0.07|15.9|101
    IDN|ID|Indonesia|P|IDR|0.12|-2.5|118
    VNM|VN|Vietnam|P|VND|0.1|16|108
    PHL|PH|Philippines|P|PHP|0.12|13|122
    IND|IN|India|P|INR|0.18|21|78
    PAK|PK|Pakistan|P|PKR|0.16|30|70
    BGD|BD|Bangladesh|P|USD|0.15|23.7|90.3
    LKA|LK|Sri Lanka|P|USD|0.18|7.9|80.7
    NPL|NP|Nepal|P|USD|0.13|28.4|84.1
    AUS|AU|Australia|P|AUD|0.1|-25|134
    NZL|NZ|New Zealand|P|NZD|0.15|-41|174
    MAC|MO|Macao|P|USD|0|22.2|113.5
    MNG|MN|Mongolia|P|USD|0.1|46.8|103
    KHM|KH|Cambodia|P|USD|0.1|12.5|104.9
    LAO|LA|Laos|P|USD|0.1|19.8|102.5
    MMR|MM|Myanmar|P|USD|0.05|21.9|95.9
    BRN|BN|Brunei|P|USD|0|4.5|114.7
    BTN|BT|Bhutan|P|USD|0.07|27.5|90.4
    MDV|MV|Maldives|P|USD|0.08|3.2|73.2
    FJI|FJ|Fiji|P|USD|0.15|-17.7|178
    PNG|PG|Papua New Guinea|P|USD|0.1|-6.3|145
    SLB|SB|Solomon Islands|P|USD|0.1|-9.6|160
    TON|TO|Tonga|P|USD|0.15|-21.2|-175.2
    VUT|VU|Vanuatu|P|USD|0.15|-15.4|166.9
    NRU|NR|Nauru|P|USD|0|-0.5|166.9
    PLW|PW|Palau|P|USD|0|7.5|134.6
    FSM|FM|Micronesia|P|USD|0|7.4|150.5
    AFG|AF|Afghanistan|P|USD|0|33.9|67.7
    WSM|WS|Samoa|P|USD|0.15|-13.8|-172
    ARE|AE|United Arab Emirates|M|AED|0.05|24|54
    SAU|SA|Saudi Arabia|M|SAR|0.15|24|45
    QAT|QA|Qatar|M|QAR|0|25.3|51.2
    KWT|KW|Kuwait|M|USD|0|29.3|47.5
    BHR|BH|Bahrain|M|USD|0.1|26|50.5
    OMN|OM|Oman|M|USD|0.05|21|57
    JOR|JO|Jordan|M|USD|0.16|31|36
    LBN|LB|Lebanon|M|USD|0.11|33.9|35.9
    IRQ|IQ|Iraq|M|USD|0|33|44
    YEM|YE|Yemen|M|USD|0|15.5|48
    ISR|IL|Israel|M|ILS|0.18|31.4|35
    EGY|EG|Egypt|M|EGP|0.14|26.8|30.8
    TUN|TN|Tunisia|M|USD|0.19|34|9.5
    MAR|MA|Morocco|M|USD|0.2|31.8|-7
    DZA|DZ|Algeria|M|USD|0.19|28|2.6
    LBY|LY|Libya|M|USD|0|26.3|17.2
    ZAF|ZA|South Africa|M|ZAR|0.15|-29|24
    NGA|NG|Nigeria|M|NGN|0.075|9|8
    KEN|KE|Kenya|M|USD|0.16|0.2|37.9
    TZA|TZ|Tanzania|M|TZS|0.18|-6.4|34.9
    GHA|GH|Ghana|M|USD|0.15|7.9|-1
    UGA|UG|Uganda|M|USD|0.18|1.4|32.3
    RWA|RW|Rwanda|M|USD|0.18|-1.9|29.9
    ZWE|ZW|Zimbabwe|M|USD|0.15|-19|29.2
    ZMB|ZM|Zambia|M|USD|0.16|-13.1|27.8
    MOZ|MZ|Mozambique|M|USD|0.16|-18.7|35.5
    BWA|BW|Botswana|M|USD|0.14|-22.3|24.7
    NAM|NA|Namibia|M|USD|0.15|-22.9|18.5
    MUS|MU|Mauritius|M|USD|0.15|-20.3|57.6
    MDG|MG|Madagascar|M|USD|0.2|-18.8|46.9
    MWI|MW|Malawi|M|USD|0.165|-13.3|34.3
    SEN|SN|Senegal|M|USD|0.18|14.5|-14.5
    CIV|CI|Côte d’Ivoire|M|USD|0.18|7.5|-5.5
    CMR|CM|Cameroon|M|USD|0.1925|7.4|12.4
    COD|CD|Congo (DRC)|M|USD|0.16|-4|21.8
    COG|CG|Congo|M|USD|0.18|-0.2|15.8
    GAB|GA|Gabon|M|USD|0.18|-0.8|11.6
    AGO|AO|Angola|M|USD|0.14|-11.2|17.9
    CPV|CV|Cabo Verde|M|USD|0.15|16|-24
    SYC|SC|Seychelles|M|USD|0.15|-4.7|55.5
    NER|NE|Niger|M|USD|0.19|17.6|8.1
    MLI|ML|Mali|M|USD|0.18|17.6|-4
    BFA|BF|Burkina Faso|M|USD|0.18|12.2|-1.6
    BEN|BJ|Benin|M|USD|0.18|9.3|2.3
    TCD|TD|Chad|M|USD|0.18|15.5|18.7
    GMB|GM|Gambia|M|USD|0.15|13.4|-15.3
    GNB|GW|Guinea-Bissau|M|USD|0.17|11.8|-15.2
    SLE|SL|Sierra Leone|M|USD|0.15|8.5|-11.8
    LBR|LR|Liberia|M|USD|0.1|6.4|-9.4
    SWZ|SZ|Eswatini|M|USD|0.15|-26.5|31.5
    MRT|MR|Mauritania|M|USD|0.16|21|-10.9
    """
}

-- Distribuzione globale dei ricercatori per milione (2018)
-- Obiettivo 1: creare un grafico a barre ordinato per rpm nel 2018. (evidenziando i valori estremi)?

SELECT 
    rpm.geounit,
    icc.country_name,
    rpm.value AS researchers_per_million
FROM 
    researchers_per_million rpm
JOIN 
    iso_country_codes icc
ON 
    rpm.geounit = icc.iso_alpha3
JOIN 
    matching_with_global_copy mwg
ON 
    rpm.geounit = mwg.geounit -- Filtro solo stati che sono nella view
WHERE 
    rpm.year = 2018
    AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
    AND icc.country_name NOT IN ('Ecuador', 'Georgia', 'Kuwait', 'Sri Lanka', 'Malaysia', 'Paraguay', 'Serbia', 'Togo', 'Thailand', 'Tunisia', 'Ukraine', 'Uruguay')
ORDER BY 
    researchers_per_million DESC;

	--Distribuzione globale della percentuale di energia rinnovabile (2018)
-- Obiettivo 2: creare un grafico a barre ordinato per renewable_energy_share_pct nel 2018.

SELECT 
    gdse.entity AS country_name,
    gdse.renewable_energy_share_pct
FROM 
    global_data_sustainable_energy gdse
JOIN 
    matching_with_global_copy mwg -- view aggiornata
ON 
    gdse.entity = mwg.country_name -- Filtro solo stati che sono nella view
WHERE 
    gdse.year = 2018
    AND gdse.entity NOT IN ('Ecuador', 'Georgia', 'Kuwait', 'Sri Lanka', 'Malaysia', 'Paraguay', 'Serbia', 'Togo', 'Thailand', 'Tunisia', 'Ukraine', 'Uruguay')
ORDER BY 
    renewable_energy_share_pct DESC;


/* Cerco una spiegazione alla discrepanza tra il numero di righe ottenuto dalla query dell'obiettivo 1 e quello
ottenuto dalla query dell'obiettivo 2

-- Paesi presenti in researchers_per_million ma non in global_data_sustainable_energy
SELECT 
    rpm.geounit,
    icc.country_name
FROM 
    researchers_per_million rpm
JOIN 
    iso_country_codes icc
ON 
    rpm.geounit = icc.iso_alpha3
LEFT JOIN 
    global_data_sustainable_energy gdse
ON 
    icc.country_name = gdse.entity AND rpm.year = gdse.year
WHERE 
    rpm.year = 2018 AND gdse.entity IS NULL;

-- Paesi presenti in global_data_sustainable_energy ma non in researchers_per_million
SELECT 
    gdse.entity AS country_name
FROM 
    global_data_sustainable_energy gdse
LEFT JOIN 
    iso_country_codes icc
ON 
    gdse.entity = icc.country_name
LEFT JOIN 
    researchers_per_million rpm
ON 
    icc.iso_alpha3 = rpm.geounit AND gdse.year = rpm.year
WHERE 
    gdse.year = 2018 AND rpm.geounit IS NULL;

*/

-- Paesi top e bottom per correlazione
-- Obiettivo 4: calcolare la correlazione tra researchers_per_million e renewable_energy_share_pct per ogni paese e trovare i 5 con le correlazioni più alte (positive) e più basse (negative)		

WITH energy_and_research_data AS (
    SELECT
        rpm.geounit AS country_code,
        gdse.entity AS country_name,
        rpm.year,
        rpm.value AS researchers_per_million,
        gdse.renewable_energy_share_pct
    FROM
        researchers_per_million rpm
    JOIN
        global_data_sustainable_energy gdse
    ON
        rpm.year = gdse.year
    JOIN
        matching_with_global_copy mwg -- view aggiornata
    ON
        rpm.geounit = mwg.geounit AND gdse.entity = mwg.country_name
    WHERE
        rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
)
SELECT
    country_code,
    country_name,
    AVG(researchers_per_million) AS avg_researchers_per_million,
    AVG(renewable_energy_share_pct) AS avg_percent_renewable
FROM
    energy_and_research_data
GROUP BY
    country_code, country_name
ORDER BY
    avg_researchers_per_million DESC; -- si può eventualmente cambiare l'ordinamento


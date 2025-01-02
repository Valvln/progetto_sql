-- Trend globale della percentuale di energia rinnovabile (2000-2022)
-- Obiettivo 6: creare un grafico a linee che mostri l'evoluzione della percentuale di energia rinnovabile a livello globale nel tempo.						

WITH filtered_energy_data AS (
    SELECT
        gdse.year,
        gdse.renewable_energy_share_pct
    FROM
        global_data_sustainable_energy gdse
    JOIN
        matching_with_global_copy mwg -- view aggiornata
    ON
        gdse.entity = mwg.country_name
    WHERE
        mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY') -- Paesi esclusi
)
SELECT
    year,
    AVG(renewable_energy_share_pct) AS avg_renewable_energy_global 
FROM
    filtered_energy_data
WHERE renewable_energy_share_pct IS NOT NULL
GROUP BY
    year
ORDER BY
    year;


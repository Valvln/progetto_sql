-- Trend globale dei ricercatori per milione (2000-2022)
-- Obiettivo 5: creare un grafico a linee che mostri l'evoluzione del numero di ricercatori per milione nel tempo, aggregando i dati a livello globale.						

WITH filtered_research_data AS (
    SELECT
        rpm.year,
        rpm.value AS researchers_per_million
    FROM
        researchers_per_million rpm
    JOIN
        matching_with_global_copy mwg
    ON
        rpm.geounit = mwg.geounit
    WHERE
        rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY') -- Paesi esclusi
)
SELECT
    year,
    AVG(researchers_per_million) AS avg_researchers_per_million_global 
FROM
    filtered_research_data
GROUP BY
    year
ORDER BY
    year;

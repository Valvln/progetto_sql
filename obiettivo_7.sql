-- Focus su paesi selezionati (caso studio)
-- Obiettivo 7; creare un grafico che confronti il trend di ricercatori per milione e la percentuale di energia rinnovabile per alcuni paesi significativi dal 2000 al 2022

WITH selected_countries_data AS (
    SELECT
        rpm.geounit AS country_code,
        rpm.year,
        rpm.value AS researchers_per_million,
        gdse.renewable_energy_share_pct,
        gdse.entity AS country_name
    FROM
        researchers_per_million rpm
    JOIN
        global_data_sustainable_energy gdse
    ON
        rpm.year = gdse.year 
	JOIN 
		matching_with_global_copy mwg 		-- UTILIZZO una copia aggiornata di mwg
	ON 
        rpm.geounit = mwg.geounit AND gdse.entity = mwg.country_name
    WHERE
        rpm.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'JPN', 'NZL', 'ZAF' ) 
		AND gdse.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'Japan', 'New Zealand', 'South Africa')
        AND rpm.year BETWEEN 2000 AND 2020
		
)
SELECT
    country_code,
    country_name,
    year,
    AVG(researchers_per_million) AS avg_researchers_per_million,
    AVG(renewable_energy_share_pct) AS avg_percent_renewable
FROM
    selected_countries_data
GROUP BY
    country_code, country_name, year
ORDER BY
    country_code, year;

/* CERCO L'ORIGINE DELL'ERRORE NELLA PRIMA VERSIONE DELLA QUERY DELL'OBIETTIVO 7

SELECT DISTINCT year
FROM researchers_per_million
WHERE geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF' );

SELECT DISTINCT year
FROM global_data_sustainable_energy
WHERE entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa');


SELECT DISTINCT r.year
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF' )
 AND g.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa');


SELECT DISTINCT r.geounit, g.entity, r.year, r.value AS researchers_per_million, g.renewable_energy_share_pct
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.year BETWEEN 2000 AND 2020
AND r.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF' )
AND g.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa');

SELECT DISTINCT r.geounit, g.entity
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.year BETWEEN 2000 AND 2020;

SELECT DISTINCT r.geounit, g.entity
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year							-- ok
JOIN matching_with_global m
ON r.geounit = m.geounit AND g.entity = m.country_name
WHERE r.year BETWEEN 2000 AND 2020;

SELECT DISTINCT r.geounit, g.entity
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
LEFT JOIN matching_with_global m
ON r.geounit = m.geounit AND g.entity = m.country_name
WHERE m.geounit IS NULL OR m.country_name IS NULL
AND r.year BETWEEN 2000 AND 2020;




SELECT r.geounit, g.entity, r.year, r.value AS researchers_per_million, g.renewable_energy_share_pct
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.year BETWEEN 2000 AND 2020
AND (r.value IS NULL OR g.renewable_energy_share_pct IS NULL);

SELECT r.year, COUNT(r.value) AS researchers_count, COUNT(g.renewable_energy_share_pct) AS renewable_count
FROM researchers_per_million r
LEFT JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.year BETWEEN 2000 AND 2020
GROUP BY r.year;

SELECT DISTINCT m.geounit, m.country_name, r.year
FROM matching_with_global m
JOIN researchers_per_million r
ON r.geounit = m.geounit
WHERE r.year BETWEEN 2000 AND 2020;

*/

/* CERCO CAUSA MANCANZA INDIA E USA NELLA LISTA DI PAESI

-- Verifica per researchers_per_million
SELECT DISTINCT geounit, year
FROM researchers_per_million
WHERE geounit IN ('USA', 'IND') AND year BETWEEN 2000 AND 2023;

-- Verifica per global_data_sustainable_energy
SELECT DISTINCT entity, year
FROM global_data_sustainable_energy
WHERE entity IN ('United States of America (the)', 'India') AND year BETWEEN 2000 AND 2023;


SELECT DISTINCT r.geounit, g.entity
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.geounit = 'USA';

SELECT DISTINCT r.geounit, r.year
FROM researchers_per_million r
JOIN global_data_sustainable_energy g
ON r.year = g.year
WHERE r.geounit IN ('USA', 'IND') AND g.entity IN ('United States', 'India');

SELECT *
FROM matching_with_global
WHERE geounit IN ('USA', 'IND') OR country_name IN ('United States', 'India');

CREATE VIEW matching_with_global_copy AS
SELECT * FROM matching_with_global;

UPDATE matching_with_global_copy
SET country_name = 'United States'
WHERE geounit = 'USA' AND country_name = 'United States of America (the)';

CREATE OR REPLACE VIEW matching_with_global_copy AS
WITH updated_data AS (
    SELECT 
        geounit,
        CASE
            WHEN country_name = 'United States of America (the)' THEN 'United States'
            ELSE country_name
        END AS country_name
    FROM matching_with_global
)
SELECT * FROM updated_data;

ATTENZIONE!!!! AGIORNARE TUTTE LE ALTRE QUERY?

*/

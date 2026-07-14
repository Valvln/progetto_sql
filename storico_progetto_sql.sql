-- Creo la tabella 'researchers_per_million' per importare i dati dal sito UNESCO

CREATE TABLE researchers_per_million (
    geounit VARCHAR(10),
    year INT,
    value FLOAT
);

-- Correggo la lunghezza massima delle stringhe accettate dalla colonna 'geounit 

ALTER TABLE researchers_per_million
	ALTER COLUMN geounit TYPE VARCHAR(50);

-- La correzione della lunghezza consente l'importazione corretta dei dati tramite la funzione \copy

-- Creo la tabella 'global_data_sustainable_energy' per importare il dataset kaggle

CREATE TABLE global_data_sustainable_energy (
    entity VARCHAR(255),                     -- Nome del Paese
    year INT,                                -- Anno
    access_to_electricity_pct FLOAT,         -- Accesso all'elettricità (% popolazione)
    access_to_clean_cooking FLOAT,           -- Accesso a combustibili puliti per cucinare
    renewable_capacity_per_capita FLOAT,     -- Capacità rinnovabile per capita
    financial_flows_dev_countries_usd FLOAT, -- Flussi finanziari ai paesi in via di sviluppo (USD)
    renewable_energy_share_pct FLOAT,        -- Quota di energia rinnovabile (%)
    electricity_fossil_fuels_twh FLOAT,      -- Elettricità da combustibili fossili (TWh)
    electricity_nuclear_twh FLOAT,           -- Elettricità nucleare (TWh)
    electricity_renewables_twh FLOAT,        -- Elettricità rinnovabile (TWh)
    low_carbon_electricity_pct FLOAT,        -- Elettricità a basse emissioni di CO2 (%)
    primary_energy_per_capita_kwh FLOAT,     -- Energia primaria pro capite (kWh/persona)
    energy_intensity_mj_per_gdp FLOAT,       -- Intensità energetica (MJ/$2017 PPP GDP)
    co2_emissions_kt FLOAT,                  -- Emissioni di CO2 (kt)
    renewables_pct_primary_energy FLOAT,     -- Quota di rinnovabili (% energia primaria)
    gdp_growth_pct FLOAT,                    -- Tasso di crescita del PIL (%)
    gdp_per_capita_usd FLOAT,                -- PIL pro capite (USD)
    population_density_p_per_km2 FLOAT,      -- Densità della popolazione (persone/Km2)
    land_area_km2 FLOAT,                     -- Superficie terrestre (Km2)
    latitude FLOAT,                          -- Latitudine (°) 
    longitude FLOAT                          -- Longitudine (°)
);


-- Verifica dell'importazione nella tabella researchers_per_million

SELECT COUNT(*) FROM researchers_per_million;

-- Campionamento dei dati

SELECT * FROM researchers_per_million LIMIT 10;
	
	
-- Verifica dell'importazione nella tabella global_data_sustainable_energy

SELECT COUNT (*) FROM global_data_sustainable_energy;

-- Controllo alcuni valori per gbse

SELECT * FROM global_data_sustainable_energy LIMIT 10;  -- l'output è corretto


/* 		-------------------------		*/


-- Selezione delle unità geografiche con copertura temporale superiore a 9 anni

SELECT geoUnit, COUNT(DISTINCT year) AS years_count
FROM researchers_per_million
GROUP BY geoUnit
HAVING COUNT(DISTINCT year) > 9;

-- Filtro su codici ISO Alpha-3 (3 caratteri)

SELECT geoUnit, COUNT(DISTINCT year) AS years_count
FROM researchers_per_million
WHERE LENGTH(geoUnit) = 3
GROUP BY geoUnit
HAVING COUNT(DISTINCT year) > 9;

-- Creo una tabella aggiuntiva con i nomi inglesi dei paesi e il rispettivo codice Alpha-3

CREATE TABLE iso_country_codes (
    country_name TEXT,
	iso_alpha3 VARCHAR(3) PRIMARY KEY
);

-- Verifica dell'importazione nella tabella iso_country_codes

SELECT * FROM iso_country_codes;


/* 		-------------------------		*/


-- Utilizzo icc per individuare le corrispondenze tra i codici geounit in rpm e i nomi dei paesi in gdse, creando una view per archiviare i risultati


CREATE VIEW matching_with_global AS
WITH country_filter AS (
    SELECT geounit
    FROM researchers_per_million
    GROUP BY geounit
    HAVING COUNT(year) > 9
),
country_matches AS (
    SELECT 
        cf.geounit,
        icc.country_name				
    FROM 
        country_filter cf
    JOIN 
        iso_country_codes icc
    ON 
        cf.geounit = icc.iso_alpha3
)
SELECT 
    geounit,
    country_name
FROM 
    country_matches;

-- Validazione della view matching_with_global

SELECT * FROM matching_with_global;


-- Creazione di una CTE di integrazione per i dati energetici e di ricerca

WITH energy_and_research_data AS (
    SELECT 
        gdse.entity,                           -- Nome del paese
        icc.iso_alpha3 AS geounit,			    -- Codice ISO Alpha-3
		gdse.year,                             -- Anno
        gdse.renewable_energy_share_pct,       -- Quota di energia rinnovabile (%)
        gdse.electricity_renewables_twh,       -- Energia elettrica da fonti rinnovabili (TWh)
        gdse.renewables_pct_primary_energy,    -- Percentuale di energie rinnovabili sull'energia primaria (%)
        rpm.value AS researchers_per_million   -- Numero di ricercatori per milione di abitanti
    FROM 
        global_data_sustainable_energy gdse
    JOIN 
        iso_country_codes icc
    ON 
        gdse.entity = icc.country_name  
    JOIN 
        researchers_per_million rpm
    ON 
        icc.iso_alpha3 = rpm.geounit AND gdse.year = rpm.year
    WHERE 
        icc.iso_alpha3 IN (SELECT geounit FROM matching_with_global_copy)
)
SELECT *
FROM energy_and_research_data;


/*
SELECT year, COUNT(DISTINCT geounit) AS state_count
FROM energy_and_research_data								
WHERE year IN (2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020)	--per contare il numero di stati che hanno dati 
GROUP BY year;

-- Per l'analisi statica scelgo l'anno 2018, che conta 58 stati con dati raccolti su 72

*/


/* 		-------------------------		*/

-- Nota: Le seguenti query escludono stati con dati discontinui per garantire la coerenza analitica

-- OBIETTIVO 1: Distribuzione globale dei ricercatori per milione (2018)
-- Grafico ordinato per facilità di confronto tra i paesi

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
    rpm.geounit = mwg.geounit
WHERE 
    rpm.year = 2018
    AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
    AND icc.country_name NOT IN ('Ecuador', 'Georgia', 'Kuwait', 'Sri Lanka', 'Malaysia', 'Paraguay', 'Serbia', 'Togo', 'Thailand', 'Tunisia', 'Ukraine', 'Uruguay')
ORDER BY 
    researchers_per_million DESC;

-- OBIETTIVO 2: Distribuzione globale della percentuale di energia rinnovabile (2018)
-- Grafico ordinato per facilità di confronto tra i paesi

SELECT 
    gdse.entity AS country_name,
    gdse.renewable_energy_share_pct
FROM 
    global_data_sustainable_energy gdse
JOIN 
    matching_with_global_copy mwg
ON 
    gdse.entity = mwg.country_name
WHERE 
    gdse.year = 2018
    AND gdse.entity NOT IN ('Ecuador', 'Georgia', 'Kuwait', 'Sri Lanka', 'Malaysia', 'Paraguay', 'Serbia', 'Togo', 'Thailand', 'Tunisia', 'Ukraine', 'Uruguay')
ORDER BY 
    renewable_energy_share_pct DESC;


/* Indagine sulla discrepanza tra i conteggi dei risultati della query 1 e della query 2

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

-- OBIETTIVO 3: Correlazione tra ricercatori per milione e quota di energia rinnovabile (dataset completo)
-- Scatter plot per l'analisi della relazione tra le due variabili

SELECT
    rpm.geounit AS country_code,
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
    matching_with_global_copy mwg
ON
    rpm.geounit = mwg.geounit AND gdse.entity = mwg.country_name
WHERE
    rpm.value IS NOT NULL
    AND gdse.renewable_energy_share_pct IS NOT NULL
    AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
ORDER BY
    country_code, year;


/* Versione semplificata della query precedente con selezione limitata alle variabili di interesse
WITH energy_and_research_data AS (
    SELECT
        rpm.geounit AS country_code,
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
        matching_with_global_copy mwg
    ON
        rpm.geounit = mwg.geounit AND gdse.entity = mwg.country_name
)
SELECT
    researchers_per_million,
    renewable_energy_share_pct
FROM
    energy_and_research_data
WHERE
    researchers_per_million IS NOT NULL
    AND renewable_energy_share_pct IS NOT NULL;
*/

-- OBIETTIVO 4: Analisi della correlazione media per paese
-- Calcolo degli indicatori aggregati per identificare pattern significativi		

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
        matching_with_global_copy mwg
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
    avg_researchers_per_million DESC;

-- OBIETTIVO 5: Evoluzione temporale dei ricercatori per milione (2000-2022)
-- Grafico a linee con aggregazione globale						

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
        rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
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

-- OBIETTIVO 6: Evoluzione temporale della quota di energia rinnovabile (2000-2022)
-- Grafico a linee con aggregazione globale						

WITH filtered_energy_data AS (
    SELECT
        gdse.year,
        gdse.renewable_energy_share_pct
    FROM
        global_data_sustainable_energy gdse
    JOIN
        matching_with_global_copy mwg
    ON
        gdse.entity = mwg.country_name
    WHERE
        mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
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

-- OBIETTIVO 7: Analisi comparativa per paesi selezionati (2000-2020)
-- Grafico a linee per il confronto dei trend di ricercatori e energia rinnovabile

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
		matching_with_global_copy mwg
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

/* Indagine sui fattori di variabilità nella query dell'Obiettivo 7
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


						-- Correlazione temporale per cluster
-- Obiettivo 8: dividere i paesi in cluster in base al numero medio di ricercatori per milione e mostrare come la correlazione tra rpm e percentuale di energia rinnovabile cambia nel tempo per ciascun cluster.


-- Divido i paesi in cluster in base alla media dei ricercatori 

WITH avg_researchers AS (
    SELECT
        rpm.geounit AS country_code,
        mwg.country_name,
        AVG(rpm.value) AS avg_researchers_per_million
    FROM
        researchers_per_million rpm
    JOIN
        matching_with_global_copy mwg
    ON
        rpm.geounit = mwg.geounit
    WHERE
        mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY') -- Esclusione paesi
    GROUP BY
        country_code, mwg.country_name
),
percentiles AS (
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS low_cutoff,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS high_cutoff
    FROM avg_researchers
),
clustered_countries AS (
    SELECT
        a.country_code,
        a.country_name,
        a.avg_researchers_per_million,
        CASE
            WHEN a.avg_researchers_per_million <= p.low_cutoff THEN 'Low'
            WHEN a.avg_researchers_per_million <= p.high_cutoff THEN 'Medium'
            ELSE 'High'
        END AS cluster
    FROM
        avg_researchers a, percentiles p
)
SELECT * 
FROM clustered_countries
ORDER BY cluster DESC;


-- Uso il clustering per cercare la correlazione per ciscun cluster e ciascun anno

WITH avg_researchers AS (
    SELECT
        rpm.geounit AS country_code,
        mwg.country_name,
        AVG(rpm.value) AS avg_researchers_per_million
    FROM
        researchers_per_million rpm
    JOIN
        matching_with_global_copy mwg
    ON
        rpm.geounit = mwg.geounit
    WHERE
        mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY') -- Esclusione paesi
    GROUP BY
        country_code, mwg.country_name
),
percentiles AS (
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS low_cutoff,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS high_cutoff
    FROM avg_researchers
),
clustered_countries AS (
    SELECT
        a.country_code,
        a.country_name,
        a.avg_researchers_per_million,
        CASE
            WHEN a.avg_researchers_per_million <= p.low_cutoff THEN 'Low'
            WHEN a.avg_researchers_per_million <= p.high_cutoff THEN 'Medium'
            ELSE 'High'
        END AS cluster
    FROM
        avg_researchers a, percentiles p
),
annual_data AS (
    SELECT
        rpm.geounit AS country_code,
        rpm.year,
        rpm.value AS researchers_per_million,
        gdse.renewable_energy_share_pct AS percent_renewable
    FROM
        researchers_per_million rpm
    JOIN
        global_data_sustainable_energy gdse
    ON
        rpm.year = gdse.year
    JOIN
        matching_with_global_copy mwg
    ON
        rpm.geounit = mwg.geounit AND gdse.entity = mwg.country_name
    WHERE
        mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY') -- Esclusione paesi
),
clustered_annual_data AS (
    SELECT
        ad.year,
        cc.cluster,
        ad.researchers_per_million,
        ad.percent_renewable
    FROM
        annual_data ad
    JOIN
        clustered_countries cc
    ON
        ad.country_code = cc.country_code
),
correlation_data AS (
    SELECT
        year,
        cluster,
        CORR(researchers_per_million, percent_renewable) AS correlation
    FROM
        clustered_annual_data
    GROUP BY
        year, cluster
)
SELECT * 
FROM correlation_data
ORDER BY cluster, year;



/*
ISO di paesi da escludere dall'analisi

ECU
GEO
KWT
LKA
MYS
PRY
SRB
TGO
THA
TUN
UKR
URY
*/
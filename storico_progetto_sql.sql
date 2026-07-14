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

SELECT
    COUNT(*) AS total_records
FROM
    researchers_per_million;

-- Campionamento dei dati

SELECT
    *
FROM
    researchers_per_million
LIMIT
    10;
	
	
-- Verifica dell'importazione nella tabella global_data_sustainable_energy

SELECT
    COUNT(*) AS total_records
FROM
    global_data_sustainable_energy;

-- Campionamento dei dati

SELECT
    *
FROM
    global_data_sustainable_energy
LIMIT
    10;


/* 		-------------------------		*/


-- Selezione delle unità geografiche con copertura temporale superiore a 9 anni

SELECT
    rpm.geounit,
    COUNT(DISTINCT rpm.year) AS years_count
FROM
    researchers_per_million rpm
GROUP BY
    rpm.geounit
HAVING
    COUNT(DISTINCT rpm.year) > 9
ORDER BY
    years_count DESC;

-- Filtro su codici ISO Alpha-3 (3 caratteri)

SELECT
    rpm.geounit,
    COUNT(DISTINCT rpm.year) AS years_count
FROM
    researchers_per_million rpm
WHERE
    LENGTH(rpm.geounit) = 3
GROUP BY
    rpm.geounit
HAVING
    COUNT(DISTINCT rpm.year) > 9
ORDER BY
    years_count DESC;

-- Creo una tabella aggiuntiva con i nomi inglesi dei paesi e il rispettivo codice Alpha-3

CREATE TABLE iso_country_codes (
    country_name TEXT,
	iso_alpha3 VARCHAR(3) PRIMARY KEY
);

-- Verifica dell'importazione nella tabella iso_country_codes

SELECT
    COUNT(*) AS total_records
FROM
    iso_country_codes;

SELECT
    *
FROM
    iso_country_codes
LIMIT
    10;


/* 		-------------------------		*/


-- Utilizzo icc per individuare le corrispondenze tra i codici geounit in rpm e i nomi dei paesi in gdse, creando una view per archiviare i risultati

CREATE VIEW matching_with_global AS
WITH country_filter AS (
    SELECT
        rpm.geounit
    FROM
        researchers_per_million rpm
    GROUP BY
        rpm.geounit
    HAVING
        COUNT(DISTINCT rpm.year) > 9
),
country_matches AS (
    SELECT
        cf.geounit,
        icc.country_name
    FROM
        country_filter cf
    INNER JOIN
        iso_country_codes icc
        ON cf.geounit = icc.iso_alpha3
)
SELECT
    geounit,
    country_name
FROM
    country_matches;

-- Validazione della view matching_with_global

SELECT
    COUNT(*) AS total_matching_countries
FROM
    matching_with_global;

SELECT
    *
FROM
    matching_with_global
ORDER BY
    geounit;


-- Creazione di una CTE di integrazione per i dati energetici e di ricerca

WITH energy_and_research_data AS (
    SELECT
        gdse.entity,                           -- Nome del paese
        icc.iso_alpha3 AS geounit,             -- Codice ISO Alpha-3
        gdse.year,                             -- Anno
        gdse.renewable_energy_share_pct,       -- Quota di energia rinnovabile (%)
        gdse.electricity_renewables_twh,       -- Energia elettrica da fonti rinnovabili (TWh)
        gdse.renewables_pct_primary_energy,    -- Percentuale di energie rinnovabili sull'energia primaria (%)
        rpm.value AS researchers_per_million   -- Numero di ricercatori per milione di abitanti
    FROM
        global_data_sustainable_energy gdse
    INNER JOIN
        iso_country_codes icc
        ON gdse.entity = icc.country_name
    INNER JOIN
        researchers_per_million rpm
        ON icc.iso_alpha3 = rpm.geounit
        AND gdse.year = rpm.year
    WHERE
        icc.iso_alpha3 IN (SELECT geounit FROM matching_with_global_copy)
        AND rpm.value IS NOT NULL
        AND gdse.renewable_energy_share_pct IS NOT NULL
)
SELECT
    *
FROM
    energy_and_research_data;


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
INNER JOIN
    iso_country_codes icc
    ON rpm.geounit = icc.iso_alpha3
INNER JOIN
    matching_with_global_copy mwg
    ON rpm.geounit = mwg.geounit
WHERE
    rpm.year = 2018
    AND rpm.value IS NOT NULL
    AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
ORDER BY
    researchers_per_million DESC;

-- OBIETTIVO 2: Distribuzione globale della percentuale di energia rinnovabile (2018)
-- Grafico ordinato per facilità di confronto tra i paesi

SELECT
    gdse.entity AS country_name,
    gdse.renewable_energy_share_pct
FROM
    global_data_sustainable_energy gdse
INNER JOIN
    matching_with_global_copy mwg
    ON gdse.entity = mwg.country_name
WHERE
    gdse.year = 2018
    AND gdse.renewable_energy_share_pct IS NOT NULL
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
INNER JOIN
    iso_country_codes icc
    ON rpm.geounit = icc.iso_alpha3
LEFT JOIN
    global_data_sustainable_energy gdse
    ON icc.country_name = gdse.entity
    AND rpm.year = gdse.year
WHERE
    rpm.year = 2018
    AND gdse.entity IS NULL;

-- Paesi presenti in global_data_sustainable_energy ma non in researchers_per_million
SELECT
    gdse.entity AS country_name
FROM
    global_data_sustainable_energy gdse
LEFT JOIN
    iso_country_codes icc
    ON gdse.entity = icc.country_name
LEFT JOIN
    researchers_per_million rpm
    ON icc.iso_alpha3 = rpm.geounit
    AND gdse.year = rpm.year
WHERE
    gdse.year = 2018
    AND rpm.geounit IS NULL;

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
INNER JOIN
    global_data_sustainable_energy gdse
    ON rpm.year = gdse.year
INNER JOIN
    matching_with_global_copy mwg
    ON rpm.geounit = mwg.geounit
    AND gdse.entity = mwg.country_name
WHERE
    rpm.value IS NOT NULL
    AND gdse.renewable_energy_share_pct IS NOT NULL
    AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
ORDER BY
    country_code,
    year;


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
    INNER JOIN
        global_data_sustainable_energy gdse
        ON rpm.year = gdse.year
    INNER JOIN
        matching_with_global_copy mwg
        ON rpm.geounit = mwg.geounit
        AND gdse.entity = mwg.country_name
    WHERE
        rpm.value IS NOT NULL
        AND gdse.renewable_energy_share_pct IS NOT NULL
        AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
)
SELECT
    country_code,
    country_name,
    COUNT(*) AS observation_count,
    ROUND(AVG(researchers_per_million)::NUMERIC, 2) AS avg_researchers_per_million,
    ROUND(AVG(renewable_energy_share_pct)::NUMERIC, 2) AS avg_percent_renewable
FROM
    energy_and_research_data
GROUP BY
    country_code,
    country_name
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
    INNER JOIN
        matching_with_global_copy mwg
        ON rpm.geounit = mwg.geounit
    WHERE
        rpm.value IS NOT NULL
        AND rpm.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
)
SELECT
    year,
    COUNT(*) AS observation_count,
    ROUND(AVG(researchers_per_million)::NUMERIC, 2) AS avg_researchers_per_million_global
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
    INNER JOIN
        matching_with_global_copy mwg
        ON gdse.entity = mwg.country_name
    WHERE
        gdse.renewable_energy_share_pct IS NOT NULL
        AND mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
)
SELECT
    year,
    COUNT(*) AS observation_count,
    ROUND(AVG(renewable_energy_share_pct)::NUMERIC, 2) AS avg_renewable_energy_global
FROM
    filtered_energy_data
GROUP BY
    year
ORDER BY
    year;

-- OBIETTIVO 7: Analisi comparativa per paesi selezionati (2000-2020)
-- Grafico a linee per il confronto dei trend di ricercatori e energia rinnovabile

WITH selected_countries_data AS (
    SELECT
        rpm.geounit AS country_code,
        gdse.entity AS country_name,
        rpm.year,
        rpm.value AS researchers_per_million,
        gdse.renewable_energy_share_pct
    FROM
        researchers_per_million rpm
    INNER JOIN
        global_data_sustainable_energy gdse
        ON rpm.year = gdse.year
    INNER JOIN
        matching_with_global_copy mwg
        ON rpm.geounit = mwg.geounit
        AND gdse.entity = mwg.country_name
    WHERE
        rpm.value IS NOT NULL
        AND gdse.renewable_energy_share_pct IS NOT NULL
        AND rpm.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'JPN', 'NZL', 'ZAF')
        AND gdse.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'Japan', 'New Zealand', 'South Africa')
        AND rpm.year BETWEEN 2000 AND 2020
)
SELECT
    country_code,
    country_name,
    year,
    ROUND(AVG(researchers_per_million)::NUMERIC, 2) AS avg_researchers_per_million,
    ROUND(AVG(renewable_energy_share_pct)::NUMERIC, 2) AS avg_percent_renewable,
    COUNT(*) AS observation_count
FROM
    selected_countries_data
GROUP BY
    country_code,
    country_name,
    year
ORDER BY
    country_code,
    year;

/* Indagine sui fattori di variabilità nella query dell'Obiettivo 7

-- Verifica della copertura temporale nei singoli dataset
SELECT
    DISTINCT rpm.year
FROM
    researchers_per_million rpm
WHERE
    rpm.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF')
ORDER BY
    rpm.year;

SELECT
    DISTINCT gdse.year
FROM
    global_data_sustainable_energy gdse
WHERE
    gdse.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa')
ORDER BY
    gdse.year;

-- Intersezione della copertura temporale
SELECT
    DISTINCT rpm.year
FROM
    researchers_per_million rpm
INNER JOIN
    global_data_sustainable_energy gdse
    ON rpm.year = gdse.year
WHERE
    rpm.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF')
    AND gdse.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa')
ORDER BY
    rpm.year;

-- Verifica delle corrispondenze paesi
SELECT
    DISTINCT rpm.geounit,
    gdse.entity,
    rpm.year,
    rpm.value AS researchers_per_million,
    gdse.renewable_energy_share_pct
FROM
    researchers_per_million rpm
INNER JOIN
    global_data_sustainable_energy gdse
    ON rpm.year = gdse.year
WHERE
    rpm.year BETWEEN 2000 AND 2020
    AND rpm.geounit IN ('DEU', 'ITA', 'USA', 'CAN', 'IND', 'JPN', 'NZL', 'ZAF')
    AND gdse.entity IN ('Germany', 'Italy', 'United States', 'Canada', 'India', 'Japan', 'New Zealand', 'South Africa')
ORDER BY
    rpm.geounit,
    rpm.year;

-- Verifica della qualità dei dati (valori mancanti)
SELECT
    rpm.geounit,
    gdse.entity,
    rpm.year,
    CASE WHEN rpm.value IS NULL THEN 'Missing' ELSE 'Present' END AS researchers_status,
    CASE WHEN gdse.renewable_energy_share_pct IS NULL THEN 'Missing' ELSE 'Present' END AS renewable_status
FROM
    researchers_per_million rpm
INNER JOIN
    global_data_sustainable_energy gdse
    ON rpm.year = gdse.year
WHERE
    rpm.year BETWEEN 2000 AND 2020
    AND (rpm.value IS NULL OR gdse.renewable_energy_share_pct IS NULL)
ORDER BY
    rpm.geounit,
    rpm.year;

*/

/* INDAGINE: Anomalie nei codici USA e IND

-- Verifica della copertura per USA e IND in researchers_per_million
SELECT
    DISTINCT rpm.geounit,
    rpm.year
FROM
    researchers_per_million rpm
WHERE
    rpm.geounit IN ('USA', 'IND')
    AND rpm.year BETWEEN 2000 AND 2023
ORDER BY
    rpm.geounit,
    rpm.year;

-- Verifica della copertura per USA e IND in global_data_sustainable_energy
SELECT
    DISTINCT gdse.entity,
    gdse.year
FROM
    global_data_sustainable_energy gdse
WHERE
    gdse.entity IN ('United States of America (the)', 'India')
    AND gdse.year BETWEEN 2000 AND 2023
ORDER BY
    gdse.entity,
    gdse.year;

-- Verifica della corrispondenza nella view matching_with_global
SELECT
    *
FROM
    matching_with_global mwg
WHERE
    mwg.geounit IN ('USA', 'IND')
    OR mwg.country_name IN ('United States', 'India')
ORDER BY
    mwg.geounit;

-- Soluzione: Creare una view aggiornata con normalizzazione dei nomi
CREATE OR REPLACE VIEW matching_with_global_copy AS
WITH normalized_data AS (
    SELECT
        mwg.geounit,
        CASE
            WHEN mwg.country_name = 'United States of America (the)' THEN 'United States'
            ELSE mwg.country_name
        END AS country_name
    FROM
        matching_with_global mwg
)
SELECT
    geounit,
    country_name
FROM
    normalized_data;

*/


						-- OBIETTIVO 8: Correlazione temporale per cluster
-- Divisione dei paesi in cluster in base al numero medio di ricercatori per milione
-- Analisi della relazione tra rpm e percentuale di energia rinnovabile per ciascun cluster

WITH avg_researchers AS (
    SELECT
        rpm.geounit AS country_code,
        mwg.country_name,
        AVG(rpm.value) AS avg_researchers_per_million
    FROM
        researchers_per_million rpm
    INNER JOIN
        matching_with_global_copy mwg
        ON rpm.geounit = mwg.geounit
    WHERE
        rpm.value IS NOT NULL
        AND mwg.geounit NOT IN ('ECU', 'GEO', 'KWT', 'LKA', 'MYS', 'PRY', 'SRB', 'TGO', 'THA', 'TUN', 'UKR', 'URY')
    GROUP BY
        country_code,
        mwg.country_name
),
percentiles AS (
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS low_cutoff,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY avg_researchers_per_million) AS high_cutoff
    FROM
        avg_researchers
),
clustered_countries AS (
    SELECT
        a.country_code,
        a.country_name,
        ROUND(a.avg_researchers_per_million::NUMERIC, 2) AS avg_researchers_per_million,
        CASE
            WHEN a.avg_researchers_per_million <= p.low_cutoff
                THEN 'Low'
            WHEN a.avg_researchers_per_million <= p.high_cutoff
                THEN 'Medium'
            ELSE
                'High'
        END AS cluster
    FROM
        avg_researchers a
    CROSS JOIN
        percentiles p
)
SELECT
    country_code,
    country_name,
    avg_researchers_per_million,
    cluster
FROM
    clustered_countries
ORDER BY
    cluster DESC,
    avg_researchers_per_million DESC;


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
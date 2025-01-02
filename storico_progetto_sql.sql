-- Creo la tabella 'researchers_per_million' per importare i dati dal sito UNESCO

CREATE TABLE researchers_per_million (
    geounit VARCHAR(10),
    year INT,
    value FLOAT
);

-- correggo il numero di stringhe accettate dalla colonna 'geounit' 

ALTER TABLE researchers_per_million
	ALTER COLUMN geounit TYPE VARCHAR(50);

-- Dopo questa correzzione sono riuscito a importare correttamente i dati tramite funzione \copy

-- Creo la tabella 'global_data_sustainable_energy' per importare il dataset kaggle

CREATE TABLE global_data_sustainable_energy (
    entity VARCHAR(255),                     -- Nome del paese
    year INT,                                -- Anno
    access_to_electricity_pct FLOAT,         -- Accesso all'elettricità (% popolazione)
    access_to_clean_cooking FLOAT,           -- Accesso a combustibili puliti per cucinare
    renewable_capacity_per_capita FLOAT,     -- Capacità rinnovabile per capita
    financial_flows_dev_countries_usd FLOAT, -- Flussi finanziari ai paesi in via di sviluppo (USD)
    renewable_energy_share_pct FLOAT,        -- Condivisione dell'energia rinnovabile (%)
    electricity_fossil_fuels_twh FLOAT,      -- Elettricità da combustibili fossili (TWh)
    electricity_nuclear_twh FLOAT,           -- Elettricità nucleare (TWh)
    electricity_renewables_twh FLOAT,        -- Elettricità rinnovabile (TWh)
    low_carbon_electricity_pct FLOAT,        -- Elettricità a basse emissioni di carbonio (%)
    primary_energy_per_capita_kwh FLOAT,     -- Energia primaria per capita (kWh/persona)
    energy_intensity_mj_per_gdp FLOAT,       -- Intensità energetica (MJ/$2017 PPP GDP)
    co2_emissions_kt FLOAT,                  -- Emissioni di CO2 (kt)
    renewables_pct_primary_energy FLOAT,     -- Rinnovabili (% energia primaria)
    gdp_growth_pct FLOAT,                    -- Crescita del PIL (%)
    gdp_per_capita_usd FLOAT,                -- PIL pro capite (USD)
    population_density_p_per_km2 FLOAT,      -- Densità popolazione (persone/Km2)
    land_area_km2 FLOAT,                     -- Area terrestre (Km2)
    latitude FLOAT,                          -- Latitudine
    longitude FLOAT                          -- Longitudine
);


-- Controllo ce l'importazione sia avvenuta correttamente per rpm

SELECT COUNT(*) FROM researchers_per_million;  -- l'ouput è corretto

-- Controllo alcuni valori per rpm

SELECT * FROM researchers_per_million LIMIT 10;  -- l'output è corretto
	
	
-- Controllo che l'importazione sia avvenuta correttamente per gbse

SELECT COUNT (*) FROM global_data_sustainable_energy;  -- l'output è corretto

-- Controllo alcuni valori per gbse

SELECT * FROM global_data_sustainable_energy LIMIT 10;  -- l'ouput è corretto


/* 		-------------------------		*/


-- Seleziono tutti i valori di 'geounit' in rpm che hanno un dati tracciati per più di 9 anni

SELECT geoUnit, COUNT(DISTINCT year) AS years_count
FROM researchers_per_million
GROUP BY geoUnit										-- l'output restituisce 121 righe
HAVING COUNT(DISTINCT year) > 9;


-- Limito i risultati a tutti gli stati in 'geounit' che hanno un acronimo di 3 caratteri

SELECT geoUnit, COUNT(DISTINCT year) AS years_count
FROM researchers_per_million
WHERE LENGTH(geoUnit) = 3								-- l'output restituisce 72 righe
GROUP BY geoUnit
HAVING COUNT(DISTINCT year) > 9;

-- Creao una tabella aggiuntiva con i nomi inglesi dei paesi e il rispettivo codice Alpha-3

CREATE TABLE iso_country_codes (
    country_name TEXT,
	iso_alpha3 VARCHAR(3) PRIMARY KEY
);

-- Controllo che l'importazione sia avvenuta correttamente per icc

SELECT * FROM iso_country_codes;			-- l'output restituisce 249 righe, corretto


/* 		-------------------------		*/


-- Uso icc per cercare le corrispondenze tra geounit in rpm e nomi di stati in gdse, e creao una view per memorizzare i risultati


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

-- Controllo che la view è stata creata correttamente

SELECT * FROM matching_with_global;			-- la view restituisce 72 risultati contenenti gli stati che hanno più di 9 anni di raccolta dati e che compaiono in gdse e rpm


-- Uso la view mwg per creare una CTE che fornisce i dati per le prossime analisi

WITH energy_and_research_data AS (
    -- Unisco i dati sull'energia rinnovabile con i dati sui ricercatori per milione
    SELECT 
        gdse.entity,                           -- Stato 
        icc.iso_alpha3 AS geounit,			    -- Acronimo
		gdse.year,                             -- Anno di raccolta dei dati
        gdse.renewable_energy_share_pct,       -- Percentuale di energia rinnovabile percentuale
        gdse.electricity_renewables_twh,       -- Elettricità rinnovabile generata
        gdse.renewables_pct_primary_energy,    -- Energia primaria rinnovabile
        rpm.value AS researchers_per_million   -- Ricercatori per milione
    FROM 
        global_data_sustainable_energy gdse
    JOIN 
        iso_country_codes icc
    ON 
        gdse.entity = icc.country_name  								-- la CTE funziona correttamente
    JOIN 
        researchers_per_million rpm
    ON 
        icc.iso_alpha3 = rpm.geounit AND gdse.year = rpm.year
    WHERE 
        icc.iso_alpha3 IN (SELECT geounit FROM matching_with_global_copy) -- view aggiornata (_copy)
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

-- ESCLUDERO' DA OGNI QUERY UNA LISTA DI STATI CHE HANNO MOSTRATO AVERE DATI RACCOLTI IN MODO DISCONTINUO

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

						-- Correlazione statica (tutti gli anni)
-- Obiettivo 3: scatter plot della correlazione tra rpm e renewable_energy_share_pct

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


/* La seguente query restituisce gli stessi risultati precedenti ma solo con le colonne researchers e renewable energy
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
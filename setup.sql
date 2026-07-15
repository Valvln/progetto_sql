-- Setup consolidato: tabelle e view necessarie per eseguire le query di analisi (obiettivo_*.sql)
-- Estratto da storico_progetto_sql.sql (fonte di riferimento per il dettaglio del processo)

-- Tabella per i dati UNESCO 'researchers per million'

CREATE TABLE researchers_per_million (
    geounit VARCHAR(10),
    year INT,
    value FLOAT
);

-- Lunghezza massima ampliata per consentire l'importazione corretta dei dati tramite \copy

ALTER TABLE researchers_per_million
    ALTER COLUMN geounit TYPE VARCHAR(50);

-- Tabella per il dataset Kaggle 'Global Data on Sustainable Energy'

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

-- Tabella di lookup nomi paese <-> codice ISO Alpha-3

CREATE TABLE iso_country_codes (
    country_name TEXT,
    iso_alpha3 VARCHAR(3) PRIMARY KEY
);

-- A questo punto importare i dati nelle tre tabelle (es. tramite \copy) prima di creare le view sottostanti

-- View: unità geografiche con >9 anni di dati in researchers_per_million, con nome paese associato

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

-- View: versione normalizzata di matching_with_global (fix del mismatch 'United States of America (the)' -> 'United States')
-- Tutte le query di analisi (obiettivo_*.sql) fanno riferimento a QUESTA view, non a matching_with_global

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

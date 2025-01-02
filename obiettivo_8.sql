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


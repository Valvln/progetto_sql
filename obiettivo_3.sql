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

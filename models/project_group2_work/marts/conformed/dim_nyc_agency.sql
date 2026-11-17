-- Agency dimension shared by both data sources
-- Grain: one row per unique NYC issuing/responding agency, plus '-1' unknown member

WITH stg_open_parking AS (
    SELECT * FROM {{ ref('stg_nyc_open_parking') }}
),

stg_311_illegal_parking AS (
    SELECT * FROM {{ ref('stg_nyc_311_illegal_parking') }}
),

all_agencies AS (
    -- NYC Open Parking and Camera Violations
    SELECT DISTINCT
        UPPER(TRIM(CAST(agency_name AS STRING))) AS agency_name
    FROM stg_open_parking
    WHERE agency_name IS NOT NULL
      AND TRIM(CAST(agency_name AS STRING)) != ''

    UNION DISTINCT

    -- 311 Service Request illegal parking complaints
    SELECT DISTINCT
        UPPER(TRIM(CAST(agency_name AS STRING))) AS agency_name
    FROM stg_311_illegal_parking
    WHERE agency_name IS NOT NULL
      AND TRIM(CAST(agency_name AS STRING)) != ''
),

agency_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['agency_name']) }} AS agency_key,
        agency_name
    FROM all_agencies
),

null_placeholder AS (
    SELECT
        '-1' AS agency_key,
        'Unknown' AS agency_name
)

SELECT * FROM agency_dimension

UNION ALL

SELECT * FROM null_placeholder
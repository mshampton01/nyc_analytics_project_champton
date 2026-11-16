-- Agency dimension shared by both data sources

WITH stg_open_parking AS (
    SELECT * FROM {{ ref('stg_nyc_open_parking') }}
),

stg_311_illegal_parking AS (
    SELECT * FROM {{ ref('stg_311_illegal_parking') }}
),

all_agencies AS(

    -- NYC Open Parking and Camera Violations
    SELECT DISTINCT CAST(agency_name AS STRING) AS agency_name
    FROM stg_open_parking
    WHERE agency_name IS NOT NULL
      
    UNION DISTINCT

    -- 311 service request illegal parking complaint type
    SELECT DISTINCT CAST(agency_name AS STRING) AS agency_name
    FROM stg_311_illegal_parking
    WHERE agency_name IS NOT NULL

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
        CAST(NULL AS STRING) AS agency_name
)

SELECT *
FROM agency_dimension

UNION ALL

SELECT *
FROM null_placeholder
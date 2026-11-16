-- Location dimension shared by both data sources
-- Grain: one row per distinct combination of borough / zip_code / precinct.

WITH stg_open_parking AS (

    SELECT *
    FROM {{ ref('stg_nyc_open_parking') }}

),

stg_311_illegal_parking AS (

    SELECT *
    FROM {{ ref('stg_311_illegal_parking') }}

),

all_locations AS (

    -- NYC Open Parking and Camera Violations
    -- ZIP code is not available in this staging model
    SELECT DISTINCT
        CAST(borough AS STRING) AS borough,
        CAST(NULL AS STRING) AS zip_code,
        CAST(precinct AS STRING) AS precinct

    FROM stg_open_parking

    WHERE borough IS NOT NULL
       OR precinct IS NOT NULL

    UNION DISTINCT

    -- NYC 311 Illegal Parking Service Requests
    SELECT DISTINCT
        CAST(borough AS STRING) AS borough,
        CAST(zip AS STRING) AS zip_code,
        CAST(police_precinct AS STRING) AS precinct

    FROM stg_311_illegal_parking

    WHERE borough IS NOT NULL
       OR police_precinct IS NOT NULL
       OR zip IS NOT NULL

),

-- Location dimension
location_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'borough', 'zip_code', 'precinct'
        ]) }} AS location_key,

        borough,
        zip_code,
        precinct

    FROM all_locations

),

-- NULL placeholder row
null_placeholder AS (

    SELECT
        '-1' AS location_key,
        CAST(NULL AS STRING) AS borough,
        CAST(NULL AS STRING) AS zip_code,
        CAST(NULL AS STRING) AS precinct

)

-- Final location dimension
SELECT * FROM location_dimension

UNION ALL

SELECT * FROM null_placeholder
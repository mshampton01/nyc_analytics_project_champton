-- Date dimension shared by NYC Open Parking and Camera Violations and 311 service request "illeagl parking" complaint type

-- Build initial CTEs for Jinja syntax to make refs to staging models easier
WITH stg_open_parking AS (
    SELECT * FROM {{ ref('stg_nyc_open_parking') }}
),

stg_311_illegal_parking AS (
    SELECT * FROM {{ ref('stg_nyc_311_illegal_parking') }}
),

-- Then union dates from the staging data together, collecting all poss dates
all_dates AS (

    -- NYC Open Parking and Camera Violations: date roles referenced by fact_parking_camera_violations
    SELECT DISTINCT CAST(issue_date AS DATE) AS full_date
    FROM stg_open_parking
    WHERE issue_date IS NOT NULL

    UNION DISTINCT

    -- 311 service requests: date roles referenced by fact_311_illegal_parking_service_request
    SELECT DISTINCT CAST(created_date AS DATE) AS full_date
    FROM stg_311_illegal_parking
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT CAST(closed_date AS DATE) AS full_date
    FROM stg_311_illegal_parking
    WHERE closed_date IS NOT NULL


),

-- Date dimension 
date_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,

        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(QUARTER FROM full_date) AS quarter,
        EXTRACT(MONTH FROM full_date) AS month,
        FORMAT_DATE('%B', full_date) AS month_name,
        EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week
       

    FROM all_dates

),

-- Null placeholder row: to handle NULL values.
-- Building fact tables should COALESCE a null source date to this key
-- Keeps all fact and date_dim joins INNER JOINs safely
-- Kimball convention to be explicit. (More to come on this)

null_placeholder AS (

    SELECT
        '-1' AS date_key,
        CAST(NULL AS DATE) AS full_date,
        CAST(NULL AS INT64) AS year,
        CAST(NULL AS INT64) AS quarter,
        CAST(NULL AS INT64) AS month,
        CAST(NULL AS STRING) AS month_name,
        CAST(NULL AS INT64) AS day_of_week

) 
-- make sure BQ knows the col types


SELECT * FROM date_dimension

UNION ALL

SELECT * FROM null_placeholder
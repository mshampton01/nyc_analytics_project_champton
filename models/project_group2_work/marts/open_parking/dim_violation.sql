-- Volation dimension for 311 illegal parking
-- Grain: one row per violation

WITH stg_open_parking AS (
    SELECT * FROM {{ ref('stg_nyc_open_parking') }}
),

distinct_violation AS (

    SELECT DISTINCT
        TRIM(violation) AS violation_type,
        status,
    FROM stg_open_parking
    WHERE violation IS NOT NULL

),
    

dim_violation AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'violation_type', 'status'
        ]) }} AS violation_key,

       violation_type,
       status

    FROM distinct_violation

)

SELECT * FROM dim_violation
-- Volation dimension for open parking and camera violation
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
    
enriched AS (
    SELECT
        violation_type,
        status,

        -- Derived high-level category based on NYC Open Parking violation descriptions
        CASE
            WHEN violation_type LIKE '%BUS LANE%' THEN 'Bus Lane'
            WHEN violation_type LIKE '%CAMERA%' THEN 'Camera'
            WHEN violation_type LIKE '%SPEED%' THEN 'Speeding'
            WHEN violation_type LIKE '%RED LIGHT%' THEN 'Camera / Automated Enforcement'
            WHEN violation_type LIKE '%PERMIT%' THEN 'Permit'
            WHEN violation_type LIKE '%DSBLTY%' THEN 'Permit & Accessibility'
            WHEN violation_type LIKE '%NO STAND%' THEN 'No Standing'
            WHEN violation_type LIKE '%NO STOPPING%' THEN 'No Stopping'
            WHEN violation_type LIKE '%PCKP DSCHRGE%' THEN 'No Standing / No Stopping'
            WHEN violation_type LIKE '%NO PARKING%' THEN 'No Parking'
            WHEN violation_type LIKE '%HYDRANT%' THEN 'Fire Hydrant'
            WHEN violation_type LIKE '%METER%' THEN 'Meter Violation'
            WHEN violation_type LIKE '%DOUBLE%' THEN 'Double Parking'
            ELSE 'Other Violation'
        END AS violation_category
    FROM distinct_violation
),

)
dim_violation AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'violation_type', 'status'
        ]) }} AS violation_key,

       violation_type,
       violation_category
       status

    FROM enriched

)

SELECT * FROM dim_violation
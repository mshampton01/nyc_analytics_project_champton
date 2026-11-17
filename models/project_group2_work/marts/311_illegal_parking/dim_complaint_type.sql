-- Complaint type for illegl parking for 311
-- Grain: one row per complaint filed for illegal parking 

WITH stg_illegal_parking AS (
    SELECT * FROM {{ ref('stg_nyc_311_illegal_parking') }}
),

distinct_complaint_type AS (

    SELECT DISTINCT
        complaint_type,
        descriptor,
        status
    FROM stg_illegal_parking
    WHERE complaint_type IS NOT NULL
    AND descriptor IS NOT NULL

),

enriched AS (

    SELECT
        complaint_type,
        descriptor,
        status,

        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

        -- Derived flag identifying 311 service request for Illegal Parking
        CASE
            WHEN complaint_type = "Illegal Parking" THEN TRUE 
            ELSE FALSE 
            END AS is_illegal_parking

    FROM distinct_complaint_type

),

dim_complaint_type AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type', 'descriptor','status'
        ]) }} AS complaint_type_key,

        complaint_type,
        descriptor,
        status,

    FROM enriched

)

SELECT * FROM dim_complaint_type

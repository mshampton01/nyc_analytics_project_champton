-- Vehicle registration dimension for open parking and camera violation
-- Grain: one row per vehicle.

WITH stg_open_parking AS (
    SELECT * FROM {{ ref('stg_nyc_open_parking') }}
),

distinct_registration AS (

    SELECT DISTINCT
        plate,
        state,
        license_type
    FROM stg_open_parking
    WHERE plate IS NOT NULL
    AND state IS NOT NULL

),

enriched AS (

    SELECT
        plate,
        state,
        license_type,

        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

        -- Derived flag identifying out-of-state registrations
        CASE
            WHEN UPPER(TRIM(state)) != 'NY' THEN TRUE
            ELSE FALSE
            END AS out_of_state

    FROM distinct_registration

),

dim_registration AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'plate', 'state'
        ]) }} AS registration_key,

       plate,
       state,
       license_type,
       out_of_state

    FROM enriched

)

SELECT * FROM dim_registration

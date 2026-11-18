-- Fact table: NYC Open Parking and Camera Violations
-- Grain: one row per unique summons number

WITH stg_open_parking AS (
    SELECT *
    FROM {{ ref('stg_nyc_open_parking') }}
),

fact_base AS (
    SELECT
        -- Identifiers
        CAST(s.summons_number AS STRING) AS summons_key,

        -- Date dimension
        COALESCE(d.date_key, '-1') AS issue_date_key,

        -- Location dimension
        COALESCE(l.location_key, '-1') AS location_key,

        -- Registration dimension
        COALESCE(r.registration_key, '-1') AS registration_key,

        -- Violation dimension
        COALESCE(v.violation_key, '-1') AS violation_key,

        -- Agency dimension
        COALESCE(a.agency_key, '-1') AS issuing_agency_key,

        -- Measures
        1 AS violation_count,
        CAST(s.fine_amount AS NUMERIC) AS fine_amount,
        CAST(s.penalty_amount AS NUMERIC) AS penalty_amount,
        CAST(s.interest_amount AS NUMERIC) AS interest_amount,
        CAST(s.reduction_amount AS NUMERIC) AS reduction_amount,
        CAST(s.payment_amount AS NUMERIC) AS payment_amount,
        CAST(s.amount_due AS NUMERIC) AS amount_due

    FROM stg_open_parking s

    LEFT JOIN {{ ref('dim_date1') }} d
        ON DATE(s.issue_date) = d.full_date

    LEFT JOIN {{ ref('dim_location1') }} l
        ON CAST(s.borough AS STRING) = l.borough
        AND l.zip_code IS NULL
        AND CAST(s.precinct AS STRING) = l.precinct

    LEFT JOIN {{ ref('dim_registration') }} r
        ON CAST(s.plate AS STRING) = r.plate
        AND CAST(s.state AS STRING) = r.state
        AND CAST(s.license_type AS STRING) = r.license_type

    LEFT JOIN {{ ref('dim_violation') }} v
        ON CAST(s.violation AS STRING) = v.violation_type

    LEFT JOIN {{ ref('dim_nyc_agency') }} a
        ON CAST(s.agency_name AS STRING) = a.agency_name
)

SELECT *
FROM fact_base
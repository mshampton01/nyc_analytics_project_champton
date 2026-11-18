WITH stg_311 AS (
    SELECT *
    FROM {{ ref('stg_311_illegal_parking') }}
),

fact_base AS (
    SELECT
        -- Identifiers
        CAST(s.request_id AS STRING) AS services_request_key,

        -- Agency dimension
        COALESCE(a.agency_key, '-1') AS request_agency_key,

        -- Created date dimension
        COALESCE(cd.date_key, '-1') AS created_date_key,

        -- Closed date dimension
        COALESCE(xd.date_key, '-1') AS closed_date_key,

        -- Location dimension
        COALESCE(l.location_key, '-1') AS location_key,

        -- Complaint type dimension
        COALESCE(c.complaint_type_key, '-1') AS complaints_key,

        -- Measure
        1 AS request_count

    FROM stg_311 s

    LEFT JOIN {{ ref('dim_nyc_agency') }} a
        ON CAST(s.agency_name AS STRING) = a.agency_name

    LEFT JOIN {{ ref('dim_date') }} cd
        ON DATE(s.created_date) = cd.full_date

    LEFT JOIN {{ ref('dim_date') }} xd
        ON DATE(s.closed_date) = xd.full_date

    LEFT JOIN {{ ref('dim_location') }} l
        ON CAST(s.borough AS STRING) = l.borough
        AND COALESCE(CAST(s.zip AS STRING), '') =
            COALESCE(l.zip_code, '')

    LEFT JOIN {{ ref('dim_complaint_type') }} c
        ON CAST(s.complaint_type AS STRING) = c.complaint_type
        AND COALESCE(CAST(s.descriptor AS STRING), '') =
            COALESCE(c.descriptor, '')
        AND CAST(s.status AS STRING) = c.status
)

SELECT *
FROM fact_base
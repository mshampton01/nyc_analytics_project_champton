-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_open_parking_data') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
           summons_number,
           issue_date,
           violation,
           county,
           issuing_agency,
           violation_time,
           violation_status
       ),

       -- Identifiers
       CAST(summons_number AS STRING) AS summons_number,

       -- Date/Time
       CAST(issue_date AS TIMESTAMP) AS issue_date,

       -- Request details
       CAST(issuing_agency AS STRING) AS agency_name,
       CAST(violation AS STRING) AS violation,
       UPPER(TRIM(CAST(violation_status AS STRING))) AS status,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(county)) IN ('NY','MN') THEN 'Manhattan'
           WHEN UPPER(TRIM(county)) IN ('BX','Bronx') THEN 'Bronx'
           WHEN UPPER(TRIM(county)) IN ('Kings','K') THEN 'Brooklyn'
           WHEN UPPER(TRIM(county)) IN ('Q','Qns') THEN 'Queens'
           WHEN UPPER(TRIM(county)) IN ('R') THEN 'Staten Island'
           ELSE 'Unknown'
       END AS borough

   FROM source

   -- Filters
   WHERE (issue_date >= '2020-01-01T00:00:00')
   AND summons_number IS NOT NULL
   AND issue_date IS NOT NULL
   AND CAST(issue_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)


   -- Deduplicate (Fixed typo: isssue_date -> issue_date)
   QUALIFY ROW_NUMBER() OVER (PARTITION BY summons_number ORDER BY issue_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_open_parking

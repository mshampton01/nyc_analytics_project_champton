-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
            job_filing_number,
            filing_date,
            approved_date, 
            signoff_date, 
            owner_s_business_name,
            applicant_license,
            applicant_first_name, 
            applicant_last_name,
            filing_representative_business_name, 
            job_type, 
            job_description, 
            initial_cost, 
            filing_status,  
            house_no,
            street_name, 
            borough, 
            applicant_street_name, 
            city, 
            state, 
            zip, 
            filing_representative_street_name, 
            filing_representative_city, 
            filing_representative_state, 
            filing_representative_zip,
            longitude, 
            latitude,
            first_permit_date,
            current_status_date,
            ),

       -- Identifiers
      CAST(job_filing_number AS STRING) AS job_application_id,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,
       CAST(signoff_date AS TIMESTAMP) AS signoff_date,
       CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
       CAST(current_status_date) AS TIMESTAMP AS current_status_date,

       -- Job details
       CAST(owner_s_business_name AS STRING) AS owner_business_name,
       CAST(Applicant_license AS STRING) AS applicant_license,
       INITCAP(TRIM(CAST(Applicant_first_name AS STRING))) AS applicant_first_name,
       INITCAP(TRIM(CAST(Applicant_last_name AS STRING))) AS applicant_last_name,
       CAST(filing_representative_business_name AS STRING) AS filing_representative_business_name,
       UPPER(TRIM(CAST(Job_type AS STRING))) AS job_type,
       CAST(Job_description AS STRING) AS job_description,
       CAST(Initial_cost AS NUMERIC) AS initial_cost,
       UPPER(TRIM(CAST(filing_status AS STRING))) AS filing_status,

      -- Location:Job Site
       CAST(house_no AS STRING) AS house_no,
       CAST(street_name AS STRING) AS street_name,
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY', '1') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX', '2') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY', '3') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY', '4') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY', '5') THEN 'Staten Island'
           ELSE 'UNKNOWN'
       END AS borough,
     --Location: Applicant Addresss
       CAST(applicant_street_name AS STRING) AS applicant_street_name,
       INITCAP(TRIM(CAST(city AS STRING))) AS applicant_city,
       UPPER(TRIM(CAST(state AS STRING))) AS applicant_state,
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}') THEN CAST(zip AS STRING)
           ELSE NULL
       END AS applicant_zip,
    -- Location: Filing Representative 
       CAST(filing_representative_street_name AS STRING) AS filing_representative_street_name,
       INITCAP(TRIM(CAST(filing_representative_city AS STRING))) AS filing_representative_city,
       UPPER(TRIM(CAST(filing_representative_state AS STRING))) AS filing_representative_state,
       CASE
           WHEN UPPER(TRIM(CAST(filing_representative_zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
           WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 5 THEN CAST(Filing_representative_zip AS STRING)
           WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 9 THEN CAST(Filing_representative_zip AS STRING)
           WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(Filing_representative_zip AS STRING), r'^\d{5}-\d{4}') THEN CAST(Filing_representative_zip AS STRING)
           ELSE NULL
       END AS filing_representative_zip,
    -- Geographic Coordinates
       CAST(longitude AS DECIMAL) AS longitude,
       CAST(latitude AS DECIMAL) AS latitude, 


       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
  WHERE job_filing_number IS NOT NULL
     AND Filing_date IS NOT NULL
     AND Borough IS NOT NULL
  

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY Filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_dob_job_filings 

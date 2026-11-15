 -- Quick test to verify source connection works
 SELECT
     summons_number,
     issue_date,
     violation,
     county
 FROM {{ source('raw', 'source_open_parking_data') }}
 LIMIT 10
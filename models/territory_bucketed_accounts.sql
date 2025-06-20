-- models/territory_bucketed_accounts.sql

WITH scored_accounts AS (
    SELECT * FROM {{ ref('scored_icp_accounts') }}
),

scored_with_segment AS (
    SELECT
        *,
        CASE 
            WHEN employee_count <= 200 THEN 'SMB'
            WHEN employee_count > 200 AND employee_count <= 1000 THEN 'Mid-Market'
            WHEN employee_count > 1000 THEN 'Enterprise'
            ELSE 'Unknown'
        END AS segment
    FROM scored_accounts
),

territory_rules AS (
    SELECT
        account_name,
        region,
        industry,
        segment,
        current_data_warehouse,
        account_score,
        projected_arr,

        CASE 
            WHEN segment = 'Mid-Market' AND region = 'North America' AND industry = 'Retail' THEN 'MM-NA-Retail'
            WHEN segment = 'Mid-Market' AND region = 'APAC' AND industry = 'Finance' AND current_data_warehouse = 'Snowflake' THEN 'MM-APAC-Finance-Snowflake'
            WHEN segment = 'SMB' AND industry = 'Government' AND current_data_warehouse != 'Snowflake' THEN 'SMB-Gov-NonSnowflake'
            WHEN segment = 'Enterprise' AND region = 'EMEA' AND industry = 'Healthcare' THEN 'EMEA-Enterprise-Healthcare'
            ELSE 'Uncategorized'
        END AS territory_bucket

    FROM scored_with_segment
)

SELECT * FROM territory_rules

WITH base AS (
    SELECT *
    FROM {{ ref('icp_flagged_accounts') }}
)

SELECT
    *,
    CASE 
        WHEN industry = 'Finance' THEN 'Interest Rates'
        WHEN industry = 'Retail' THEN 'Tariffs, Unemployment'
        WHEN industry = 'Manufacturing' THEN 'Tariffs'
        WHEN industry = 'Government' THEN 'Government Policy'
        WHEN industry = 'Healthcare' THEN 'Policy, Funding'
        ELSE 'None'
    END AS macro_sensitivity
FROM base
{{ config(materialized = 'table') }}

-- 1. Base: Use all accounts (not filtering by icp_fit)
WITH base AS (
    SELECT *
    FROM {{ ref('icp_with_sensitivity') }}  -- This has all accounts, with or without icp_fit
),

-- 2. Score each account based on various dimensions
scored AS (
    SELECT
        *,
        -- Engagement Score
        CASE
            WHEN engagement_score > 70              THEN 3
            WHEN engagement_score BETWEEN 40 AND 70 THEN 2
            ELSE                                        1
        END AS score_engagement,

        -- BI Tool Alignment Score
        CASE
            WHEN LOWER(bi_tool) IN ('tableau','looker','power bi','sigma') THEN 2
            ELSE 0
        END AS score_bi_tool,

        -- BI Contract Expiry Score
        CASE
            WHEN bi_contract_end IS NOT NULL 
                 AND bi_contract_end <= CURRENT_DATE + INTERVAL '90 days'
            THEN 2 ELSE 0
        END AS score_bi_expiry,

        -- Tech Stack Score
        CASE
            WHEN LOWER(tech_stack) = 'snowflake' THEN 2
            WHEN tech_stack IN ('AWS', 'Azure', 'GCP') THEN 1
            ELSE 0
        END AS score_tech,

        -- Region Score
        CASE
            WHEN region IN ('North America', 'EMEA') THEN 1
            ELSE 0
        END AS score_region
    FROM base
),

-- 3. Add overall account_score
score_sum AS (
    SELECT
        *,
        score_engagement
      + score_bi_tool
      + score_bi_expiry
      + score_tech
      + score_region AS account_score
    FROM scored
),

-- 4. Add stage-based win probabilities
stage_prob AS (
    SELECT
        *,
        CASE opportunity_stage
            WHEN 'Prospecting' THEN 0.10
            WHEN 'Demo'        THEN 0.25
            WHEN 'Proposal'    THEN 0.50
            WHEN 'Closed Won'  THEN 1.00
            ELSE                    0.00
        END AS stage_win_prob
    FROM score_sum
),

-- 5. Apply macro sensitivity factor
macro_factor AS (
    SELECT
        *,
        CASE macro_sensitivity
            WHEN 'Interest Rates'            THEN 0.90
            WHEN 'Tariffs'                   THEN 0.85
            WHEN 'Tariffs, Unemployment'     THEN 0.80
            WHEN 'Government Policy'         THEN 0.80
            WHEN 'Policy, Funding'           THEN 0.90
            ELSE                                  1.00
        END AS macro_risk_factor
    FROM stage_prob
)

-- 6. Final projection
SELECT
    *,
    opportunity_value * stage_win_prob * macro_risk_factor AS projected_arr
FROM macro_factor
ORDER BY account_score DESC

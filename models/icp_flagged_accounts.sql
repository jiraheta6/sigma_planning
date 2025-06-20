SELECT
    *,
    CASE 
        WHEN employee_count BETWEEN 200 AND 2000 
             AND LOWER(current_data_warehouse) = 'snowflake'
        THEN TRUE
        ELSE FALSE
    END AS icp_fit
FROM ops_raw.synthetic_b2b_sales_data 

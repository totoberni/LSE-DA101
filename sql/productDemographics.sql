-- ========================================================================
-- Product Sales by Demographics Analysis
-- ========================================================================

-- First, let's create a helper view for product rankings to reuse across tables
DROP VIEW IF EXISTS product_rankings CASCADE;

CREATE OR REPLACE VIEW product_rankings AS
WITH product_avg_spending AS (
    SELECT 
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
)
SELECT 
    'Alcohol' AS Product, Avg_AmtLiq AS Avg_Spending
FROM product_avg_spending
UNION ALL
SELECT 
    'Vegetables' AS Product, Avg_AmtVege AS Avg_Spending
FROM product_avg_spending
UNION ALL
SELECT 
    'Meat' AS Product, Avg_AmtNonVeg AS Avg_Spending
FROM product_avg_spending
UNION ALL
SELECT 
    'Fish' AS Product, Avg_AmtPes AS Avg_Spending
FROM product_avg_spending
UNION ALL
SELECT 
    'Chocolates' AS Product, Avg_AmtChocolates AS Avg_Spending
FROM product_avg_spending
UNION ALL
SELECT 
    'Commodities' AS Product, Avg_AmtComm AS Avg_Spending
FROM product_avg_spending
ORDER BY Avg_Spending DESC;

-- ========================================================================
-- Table 1: Product Analysis by Country
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_country CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_country AS
WITH 
-- Get country list
country_list AS (
    SELECT DISTINCT Country
    FROM customer_data_combined
    ORDER BY Country
),
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Calculate metrics by country
country_metrics AS (
    SELECT
        Country,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
    GROUP BY Country
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Total_Spending::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Total_Spending::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Total_Spending::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Total_Spending::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Total_Spending::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Total_Spending::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Total_Spending::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Total_Spending::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    CASE
        WHEN t.rn = 1 THEN 'Top Product: ' || t.Product
        ELSE 'Top ' || t.rn::text || ' Product: ' || t.Product
    END AS Metric,
    t.Avg_Spending::text AS Global,
    MAX(CASE WHEN pc.product_country = 'AUS' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN pc.product_country = 'CA' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS CA,
    MAX(CASE WHEN pc.product_country = 'GER' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS GER,
    MAX(CASE WHEN pc.product_country = 'IND' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS IND,
    MAX(CASE WHEN pc.product_country = 'ME' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS ME,
    MAX(CASE WHEN pc.product_country = 'SA' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS SA,
    MAX(CASE WHEN pc.product_country = 'SP' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS SP,
    MAX(CASE WHEN pc.product_country = 'US' AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS US
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        Country AS product_country,
        'Alcohol' AS product_name,
        Avg_AmtLiq AS product_spending
    FROM country_metrics
    UNION ALL
    SELECT 
        Country AS product_country,
        'Vegetables' AS product_name,
        Avg_AmtVege AS product_spending
    FROM country_metrics
    UNION ALL
    SELECT 
        Country AS product_country,
        'Meat' AS product_name,
        Avg_AmtNonVeg AS product_spending
    FROM country_metrics
    UNION ALL
    SELECT 
        Country AS product_country,
        'Fish' AS product_name,
        Avg_AmtPes AS product_spending
    FROM country_metrics
    UNION ALL
    SELECT 
        Country AS product_country,
        'Chocolates' AS product_name,
        Avg_AmtChocolates AS product_spending
    FROM country_metrics
    UNION ALL
    SELECT 
        Country AS product_country,
        'Commodities' AS product_name,
        Avg_AmtComm AS product_spending
    FROM country_metrics
) pc GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Complain_Rate::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Complain_Rate::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Complain_Rate::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Complain_Rate::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Complain_Rate::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Complain_Rate::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Complain_Rate::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Complain_Rate::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Response_Rate::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Response_Rate::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Response_Rate::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Response_Rate::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Response_Rate::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Response_Rate::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Response_Rate::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Response_Rate::text ELSE NULL END) AS US
FROM country_metrics;

-- ========================================================================
-- Table 2: Product Analysis by Age Group
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_age_group CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_age_group AS
WITH 
-- Create equal-sized age brackets using NTILE
age_ntile AS (
    SELECT 
        ID,
        2025 - Year_Birth AS Age,
        NTILE(6) OVER (ORDER BY 2025 - Year_Birth) AS group_order,
        AmtLiq, AmtVege, AmtNonVeg, AmtPes, AmtChocolates, AmtComm, 
        Recency, Complain, Response
    FROM customer_data_combined
),
-- Calculate bracket ranges
age_bracket_ranges AS (
    SELECT 
        group_order,
        'Age ' || MIN(Age)::int || '-' || MAX(Age)::int AS Age_Group
    FROM age_ntile
    GROUP BY group_order
),
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Join age data with bracket ranges
age_with_brackets AS (
    SELECT
        n.*,
        br.Age_Group
    FROM age_ntile n
    JOIN age_bracket_ranges br ON n.group_order = br.group_order
),
-- Calculate metrics by age group
age_group_metrics AS (
    SELECT
        Age_Group,
        group_order,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM age_with_brackets
    GROUP BY Age_Group, group_order
    ORDER BY group_order
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN group_order = 1 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_1,
    MAX(CASE WHEN group_order = 2 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_2,
    MAX(CASE WHEN group_order = 3 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_3,
    MAX(CASE WHEN group_order = 4 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_4,
    MAX(CASE WHEN group_order = 5 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_5,
    MAX(CASE WHEN group_order = 6 THEN Avg_Total_Spending::text ELSE NULL END) AS Age_Group_6
FROM age_group_metrics

UNION ALL

SELECT
    CASE
        WHEN t.rn = 1 THEN 'Top Product: ' || t.Product
        ELSE 'Top ' || t.rn::text || ' Product: ' || t.Product
    END AS Metric,
    t.Avg_Spending::text AS Global,
    MAX(CASE WHEN pc.group_order = 1 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_1,
    MAX(CASE WHEN pc.group_order = 2 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_2,
    MAX(CASE WHEN pc.group_order = 3 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_3,
    MAX(CASE WHEN pc.group_order = 4 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_4,
    MAX(CASE WHEN pc.group_order = 5 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_5,
    MAX(CASE WHEN pc.group_order = 6 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Age_Group_6
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Alcohol' AS product_name,
        am.Avg_AmtLiq AS product_spending
    FROM age_group_metrics am
    UNION ALL
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Vegetables' AS product_name,
        am.Avg_AmtVege AS product_spending
    FROM age_group_metrics am
    UNION ALL
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Meat' AS product_name,
        am.Avg_AmtNonVeg AS product_spending
    FROM age_group_metrics am
    UNION ALL
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Fish' AS product_name,
        am.Avg_AmtPes AS product_spending
    FROM age_group_metrics am
    UNION ALL
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Chocolates' AS product_name,
        am.Avg_AmtChocolates AS product_spending
    FROM age_group_metrics am
    UNION ALL
    SELECT 
        am.Age_Group AS product_age_group,
        am.group_order,
        'Commodities' AS product_name,
        am.Avg_AmtComm AS product_spending
    FROM age_group_metrics am
) pc 
GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN group_order = 1 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_1,
    MAX(CASE WHEN group_order = 2 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_2,
    MAX(CASE WHEN group_order = 3 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_3,
    MAX(CASE WHEN group_order = 4 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_4,
    MAX(CASE WHEN group_order = 5 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_5,
    MAX(CASE WHEN group_order = 6 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Age_Group_6
FROM age_group_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN group_order = 1 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_1,
    MAX(CASE WHEN group_order = 2 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_2,
    MAX(CASE WHEN group_order = 3 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_3,
    MAX(CASE WHEN group_order = 4 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_4,
    MAX(CASE WHEN group_order = 5 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_5,
    MAX(CASE WHEN group_order = 6 THEN Avg_Complain_Rate::text ELSE NULL END) AS Age_Group_6
FROM age_group_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN group_order = 1 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_1,
    MAX(CASE WHEN group_order = 2 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_2,
    MAX(CASE WHEN group_order = 3 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_3,
    MAX(CASE WHEN group_order = 4 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_4,
    MAX(CASE WHEN group_order = 5 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_5,
    MAX(CASE WHEN group_order = 6 THEN Avg_Response_Rate::text ELSE NULL END) AS Age_Group_6
FROM age_group_metrics;

-- ========================================================================
-- Table 3: Product Analysis by Family Size
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_family_size CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_family_size AS
WITH 
-- Calculate family size
family_size_data AS (
    SELECT
        *,
        (1 + Kidhome + Teenhome + 
            CASE 
                WHEN UPPER(Marital_Status) IN ('TOGETHER', 'MARRIED') THEN 1 
                ELSE 0 
            END) AS Family_Size
    FROM customer_data_combined
),
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Get list of family sizes to include
family_size_list AS (
    SELECT generate_series(1, 5) AS Family_Size  -- Using 1-5 since most families in the data likely fall in this range
),
-- Calculate metrics by family size group
family_size_metrics AS (
    SELECT
        fs.Family_Size::text AS Family_Size_Group,
        ROUND(AVG(fsd.AmtLiq + fsd.AmtVege + fsd.AmtNonVeg + fsd.AmtPes + fsd.AmtChocolates + fsd.AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(fsd.AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(fsd.AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(fsd.AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(fsd.AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(fsd.AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(fsd.AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN fsd.Recency = 0 THEN NULL ELSE 1.0/fsd.Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(fsd.Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(fsd.Response)::numeric, 4) AS Avg_Response_Rate
    FROM family_size_list fs
    LEFT JOIN family_size_data fsd ON fsd.Family_Size = fs.Family_Size
    GROUP BY fs.Family_Size
    ORDER BY fs.Family_Size
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Family_Size_Group = '1' THEN Avg_Total_Spending::text ELSE NULL END) AS "Family_Size_1",
    MAX(CASE WHEN Family_Size_Group = '2' THEN Avg_Total_Spending::text ELSE NULL END) AS "Family_Size_2",
    MAX(CASE WHEN Family_Size_Group = '3' THEN Avg_Total_Spending::text ELSE NULL END) AS "Family_Size_3",
    MAX(CASE WHEN Family_Size_Group = '4' THEN Avg_Total_Spending::text ELSE NULL END) AS "Family_Size_4",
    MAX(CASE WHEN Family_Size_Group = '5' THEN Avg_Total_Spending::text ELSE NULL END) AS "Family_Size_5"
FROM family_size_metrics

UNION ALL

SELECT
    CASE
        WHEN rn = 1 THEN 'Top Product: ' || Product
        ELSE 'Top ' || rn::text || ' Product: ' || Product
    END AS Metric,
    Avg_Spending::text AS Global,
    MAX(CASE WHEN product_family_size = '1' AND product_name = Product THEN product_spending::text ELSE NULL END) AS "Family_Size_1",
    MAX(CASE WHEN product_family_size = '2' AND product_name = Product THEN product_spending::text ELSE NULL END) AS "Family_Size_2",
    MAX(CASE WHEN product_family_size = '3' AND product_name = Product THEN product_spending::text ELSE NULL END) AS "Family_Size_3",
    MAX(CASE WHEN product_family_size = '4' AND product_name = Product THEN product_spending::text ELSE NULL END) AS "Family_Size_4",
    MAX(CASE WHEN product_family_size = '5' AND product_name = Product THEN product_spending::text ELSE NULL END) AS "Family_Size_5"
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        Family_Size_Group AS product_family_size,
        'Alcohol' AS product_name,
        Avg_AmtLiq AS product_spending
    FROM family_size_metrics
    UNION ALL
    SELECT 
        Family_Size_Group AS product_family_size,
        'Vegetables' AS product_name,
        Avg_AmtVege AS product_spending
    FROM family_size_metrics
    UNION ALL
    SELECT 
        Family_Size_Group AS product_family_size,
        'Meat' AS product_name,
        Avg_AmtNonVeg AS product_spending
    FROM family_size_metrics
    UNION ALL
    SELECT 
        Family_Size_Group AS product_family_size,
        'Fish' AS product_name,
        Avg_AmtPes AS product_spending
    FROM family_size_metrics
    UNION ALL
    SELECT 
        Family_Size_Group AS product_family_size,
        'Chocolates' AS product_name,
        Avg_AmtChocolates AS product_spending
    FROM family_size_metrics
    UNION ALL
    SELECT 
        Family_Size_Group AS product_family_size,
        'Commodities' AS product_name,
        Avg_AmtComm AS product_spending
    FROM family_size_metrics
) pc GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Family_Size_Group = '1' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS "Family_Size_1",
    MAX(CASE WHEN Family_Size_Group = '2' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS "Family_Size_2",
    MAX(CASE WHEN Family_Size_Group = '3' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS "Family_Size_3",
    MAX(CASE WHEN Family_Size_Group = '4' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS "Family_Size_4",
    MAX(CASE WHEN Family_Size_Group = '5' THEN Avg_Purchase_Frequency::text ELSE NULL END) AS "Family_Size_5"
FROM family_size_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Family_Size_Group = '1' THEN Avg_Complain_Rate::text ELSE NULL END) AS "Family_Size_1",
    MAX(CASE WHEN Family_Size_Group = '2' THEN Avg_Complain_Rate::text ELSE NULL END) AS "Family_Size_2",
    MAX(CASE WHEN Family_Size_Group = '3' THEN Avg_Complain_Rate::text ELSE NULL END) AS "Family_Size_3",
    MAX(CASE WHEN Family_Size_Group = '4' THEN Avg_Complain_Rate::text ELSE NULL END) AS "Family_Size_4",
    MAX(CASE WHEN Family_Size_Group = '5' THEN Avg_Complain_Rate::text ELSE NULL END) AS "Family_Size_5"
FROM family_size_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Family_Size_Group = '1' THEN Avg_Response_Rate::text ELSE NULL END) AS "Family_Size_1",
    MAX(CASE WHEN Family_Size_Group = '2' THEN Avg_Response_Rate::text ELSE NULL END) AS "Family_Size_2",
    MAX(CASE WHEN Family_Size_Group = '3' THEN Avg_Response_Rate::text ELSE NULL END) AS "Family_Size_3",
    MAX(CASE WHEN Family_Size_Group = '4' THEN Avg_Response_Rate::text ELSE NULL END) AS "Family_Size_4",
    MAX(CASE WHEN Family_Size_Group = '5' THEN Avg_Response_Rate::text ELSE NULL END) AS "Family_Size_5"
FROM family_size_metrics;

-- ========================================================================
-- Table 4: Product Analysis by Income Bracket
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_income CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_income AS
WITH 
-- Create equal-sized income brackets using NTILE
income_ntile AS (
    SELECT 
        ID,
        Income_Numeric,
        NTILE(6) OVER (ORDER BY Income_Numeric) AS bracket_order,
        AmtLiq, AmtVege, AmtNonVeg, AmtPes, AmtChocolates, AmtComm, 
        Recency, Complain, Response
    FROM customer_data_combined
    WHERE Income_Numeric IS NOT NULL
),
-- Calculate bracket ranges
bracket_ranges AS (
    SELECT 
        bracket_order,
        '$' || MIN(FLOOR(Income_Numeric))::int || '-$' || MAX(FLOOR(Income_Numeric))::int AS Income_Bracket
    FROM income_ntile
    GROUP BY bracket_order
),
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Join income data with bracket ranges
income_with_brackets AS (
    SELECT
        n.*,
        br.Income_Bracket
    FROM income_ntile n
    JOIN bracket_ranges br ON n.bracket_order = br.bracket_order
),
-- Calculate metrics by income bracket
income_metrics AS (
    SELECT
        Income_Bracket,
        bracket_order,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM income_with_brackets
    GROUP BY Income_Bracket, bracket_order
    ORDER BY bracket_order
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN bracket_order = 1 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_1,
    MAX(CASE WHEN bracket_order = 2 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_2,
    MAX(CASE WHEN bracket_order = 3 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_3,
    MAX(CASE WHEN bracket_order = 4 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_4,
    MAX(CASE WHEN bracket_order = 5 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_5,
    MAX(CASE WHEN bracket_order = 6 THEN Avg_Total_Spending::text ELSE NULL END) AS Income_Bracket_6
FROM income_metrics

UNION ALL

SELECT
    CASE
        WHEN t.rn = 1 THEN 'Top Product: ' || t.Product
        ELSE 'Top ' || t.rn::text || ' Product: ' || t.Product
    END AS Metric,
    t.Avg_Spending::text AS Global,
    MAX(CASE WHEN pc.bracket_order = 1 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_1,
    MAX(CASE WHEN pc.bracket_order = 2 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_2,
    MAX(CASE WHEN pc.bracket_order = 3 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_3,
    MAX(CASE WHEN pc.bracket_order = 4 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_4,
    MAX(CASE WHEN pc.bracket_order = 5 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_5,
    MAX(CASE WHEN pc.bracket_order = 6 AND pc.product_name = t.Product THEN pc.product_spending::text ELSE NULL END) AS Income_Bracket_6
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Alcohol' AS product_name,
        im.Avg_AmtLiq AS product_spending
    FROM income_metrics im
    UNION ALL
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Vegetables' AS product_name,
        im.Avg_AmtVege AS product_spending
    FROM income_metrics im
    UNION ALL
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Meat' AS product_name,
        im.Avg_AmtNonVeg AS product_spending
    FROM income_metrics im
    UNION ALL
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Fish' AS product_name,
        im.Avg_AmtPes AS product_spending
    FROM income_metrics im
    UNION ALL
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Chocolates' AS product_name,
        im.Avg_AmtChocolates AS product_spending
    FROM income_metrics im
    UNION ALL
    SELECT 
        im.Income_Bracket AS product_income_bracket,
        im.bracket_order,
        'Commodities' AS product_name,
        im.Avg_AmtComm AS product_spending
    FROM income_metrics im
) pc
GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN bracket_order = 1 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_1,
    MAX(CASE WHEN bracket_order = 2 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_2,
    MAX(CASE WHEN bracket_order = 3 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_3,
    MAX(CASE WHEN bracket_order = 4 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_4,
    MAX(CASE WHEN bracket_order = 5 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_5,
    MAX(CASE WHEN bracket_order = 6 THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Income_Bracket_6
FROM income_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN bracket_order = 1 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_1,
    MAX(CASE WHEN bracket_order = 2 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_2,
    MAX(CASE WHEN bracket_order = 3 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_3,
    MAX(CASE WHEN bracket_order = 4 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_4,
    MAX(CASE WHEN bracket_order = 5 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_5,
    MAX(CASE WHEN bracket_order = 6 THEN Avg_Complain_Rate::text ELSE NULL END) AS Income_Bracket_6
FROM income_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN bracket_order = 1 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_1,
    MAX(CASE WHEN bracket_order = 2 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_2,
    MAX(CASE WHEN bracket_order = 3 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_3,
    MAX(CASE WHEN bracket_order = 4 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_4,
    MAX(CASE WHEN bracket_order = 5 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_5,
    MAX(CASE WHEN bracket_order = 6 THEN Avg_Response_Rate::text ELSE NULL END) AS Income_Bracket_6
FROM income_metrics;

-- ========================================================================
-- Table 5: Product Analysis by Education
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_education CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_education AS
WITH 
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Get list of education levels
education_list AS (
    SELECT Education FROM (
        SELECT DISTINCT Education,
            CASE 
                WHEN Education = 'Basic' THEN 1
                WHEN Education = '2n Cycle' THEN 2
                WHEN Education = 'Graduation' THEN 3
                WHEN Education = 'Master' THEN 4
                WHEN Education = 'PhD' THEN 5
                ELSE 6
            END AS education_order
        FROM customer_data_combined
    ) sub
    ORDER BY education_order
),
-- Calculate metrics by education level
education_metrics AS (
    SELECT
        Education,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
    GROUP BY Education
    ORDER BY 
        CASE 
            WHEN Education = 'Basic' THEN 1
            WHEN Education = '2n Cycle' THEN 2
            WHEN Education = 'Graduation' THEN 3
            WHEN Education = 'Master' THEN 4
            WHEN Education = 'PhD' THEN 5
            ELSE 6
        END
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 0) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Education_1,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 1) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Education_2,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 2) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Education_3,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 3) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Education_4,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 4) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Education_5
FROM education_metrics

UNION ALL

SELECT
    CASE
        WHEN rn = 1 THEN 'Top Product: ' || Product
        ELSE 'Top ' || rn::text || ' Product: ' || Product
    END AS Metric,
    Avg_Spending::text AS Global,
    MAX(CASE WHEN product_education = (SELECT Education FROM education_list LIMIT 1 OFFSET 0) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Education_1,
    MAX(CASE WHEN product_education = (SELECT Education FROM education_list LIMIT 1 OFFSET 1) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Education_2,
    MAX(CASE WHEN product_education = (SELECT Education FROM education_list LIMIT 1 OFFSET 2) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Education_3,
    MAX(CASE WHEN product_education = (SELECT Education FROM education_list LIMIT 1 OFFSET 3) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Education_4,
    MAX(CASE WHEN product_education = (SELECT Education FROM education_list LIMIT 1 OFFSET 4) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Education_5
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        Education AS product_education,
        'Alcohol' AS product_name,
        Avg_AmtLiq AS product_spending
    FROM education_metrics
    UNION ALL
    SELECT 
        Education AS product_education,
        'Vegetables' AS product_name,
        Avg_AmtVege AS product_spending
    FROM education_metrics
    UNION ALL
    SELECT 
        Education AS product_education,
        'Meat' AS product_name,
        Avg_AmtNonVeg AS product_spending
    FROM education_metrics
    UNION ALL
    SELECT 
        Education AS product_education,
        'Fish' AS product_name,
        Avg_AmtPes AS product_spending
    FROM education_metrics
    UNION ALL
    SELECT 
        Education AS product_education,
        'Chocolates' AS product_name,
        Avg_AmtChocolates AS product_spending
    FROM education_metrics
    UNION ALL
    SELECT 
        Education AS product_education,
        'Commodities' AS product_name,
        Avg_AmtComm AS product_spending
    FROM education_metrics
) pc GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 0) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Education_1,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 1) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Education_2,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 2) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Education_3,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 3) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Education_4,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 4) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Education_5
FROM education_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 0) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Education_1,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 1) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Education_2,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 2) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Education_3,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 3) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Education_4,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 4) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Education_5
FROM education_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 0) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Education_1,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 1) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Education_2,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 2) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Education_3,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 3) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Education_4,
    MAX(CASE WHEN Education = (SELECT Education FROM education_list LIMIT 1 OFFSET 4) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Education_5
FROM education_metrics;

-- ========================================================================
-- Table 6: Product Analysis by Customer Tenure
-- ========================================================================
DROP VIEW IF EXISTS product_analysis_by_tenure CASCADE;

CREATE OR REPLACE VIEW product_analysis_by_tenure AS
WITH 
-- Calculate customer tenure
tenure_data AS (
    SELECT
        *,
        DATE_PART('year', AGE('2025-04-09'::date, Customer_Date)) + 
        DATE_PART('month', AGE('2025-04-09'::date, Customer_Date))/12.0 AS Years_Customer
    FROM customer_data_combined
    WHERE Customer_Date IS NOT NULL
),
-- Calculate tenure range
tenure_range AS (
    SELECT 
        MIN(Years_Customer) AS min_tenure,
        MAX(Years_Customer) AS max_tenure,
        (MAX(Years_Customer) - MIN(Years_Customer)) / 6 AS tenure_interval
    FROM tenure_data
),
-- Calculate global averages
global_metrics AS (
    SELECT
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM customer_data_combined
),
-- Get top 5 products
top_products AS (
    SELECT Product, Avg_Spending
    FROM product_rankings
    LIMIT 5
),
-- Calculate metrics by tenure group
tenure_metrics AS (
    SELECT
        CASE 
            WHEN Years_Customer < min_tenure + tenure_interval THEN ROUND(min_tenure::numeric, 1) || '-' || ROUND((min_tenure + tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 2*tenure_interval THEN ROUND((min_tenure + tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 2*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 3*tenure_interval THEN ROUND((min_tenure + 2*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 3*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 4*tenure_interval THEN ROUND((min_tenure + 3*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 4*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 5*tenure_interval THEN ROUND((min_tenure + 4*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 5*tenure_interval)::numeric, 1) || ' Years'
            ELSE ROUND((min_tenure + 5*tenure_interval)::numeric, 1) || '-' || ROUND(max_tenure::numeric, 1) || ' Years'
        END AS Tenure_Group,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(AVG(CASE WHEN Recency = 0 THEN 1 ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(Complain)::numeric, 4) AS Avg_Complain_Rate,
        ROUND(AVG(Response)::numeric, 4) AS Avg_Response_Rate
    FROM tenure_data, tenure_range
    GROUP BY 
        CASE 
            WHEN Years_Customer < min_tenure + tenure_interval THEN ROUND(min_tenure::numeric, 1) || '-' || ROUND((min_tenure + tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 2*tenure_interval THEN ROUND((min_tenure + tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 2*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 3*tenure_interval THEN ROUND((min_tenure + 2*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 3*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 4*tenure_interval THEN ROUND((min_tenure + 3*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 4*tenure_interval)::numeric, 1) || ' Years'
            WHEN Years_Customer < min_tenure + 5*tenure_interval THEN ROUND((min_tenure + 4*tenure_interval)::numeric, 1) || '-' || ROUND((min_tenure + 5*tenure_interval)::numeric, 1) || ' Years'
            ELSE ROUND((min_tenure + 5*tenure_interval)::numeric, 1) || '-' || ROUND(max_tenure::numeric, 1) || ' Years'
        END
    ORDER BY MIN(Years_Customer)
),
-- Get list of tenure groups
tenure_group_list AS (
    SELECT DISTINCT Tenure_Group
    FROM tenure_metrics
    ORDER BY Tenure_Group
)
-- Build the final pivot table
SELECT
    'Global Average Total Spending' AS Metric,
    (SELECT Avg_Total_Spending FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 0) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_1,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 1) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_2,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 2) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_3,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 3) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_4,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 4) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_5,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 5) 
        THEN Avg_Total_Spending::text ELSE NULL END) AS Tenure_Group_6
FROM tenure_metrics

UNION ALL

SELECT
    CASE
        WHEN rn = 1 THEN 'Top Product: ' || Product
        ELSE 'Top ' || rn::text || ' Product: ' || Product
    END AS Metric,
    Avg_Spending::text AS Global,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 0) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_1,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 1) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_2,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 2) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_3,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 3) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_4,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 4) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_5,
    MAX(CASE WHEN product_tenure_group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 5) 
        AND product_name = Product THEN product_spending::text ELSE NULL END) AS Tenure_Group_6
FROM (
    SELECT 
        Product, 
        Avg_Spending, 
        ROW_NUMBER() OVER (ORDER BY Avg_Spending DESC) AS rn
    FROM top_products
) t
CROSS JOIN (
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Alcohol' AS product_name,
        Avg_AmtLiq AS product_spending
    FROM tenure_metrics
    UNION ALL
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Vegetables' AS product_name,
        Avg_AmtVege AS product_spending
    FROM tenure_metrics
    UNION ALL
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Meat' AS product_name,
        Avg_AmtNonVeg AS product_spending
    FROM tenure_metrics
    UNION ALL
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Fish' AS product_name,
        Avg_AmtPes AS product_spending
    FROM tenure_metrics
    UNION ALL
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Chocolates' AS product_name,
        Avg_AmtChocolates AS product_spending
    FROM tenure_metrics
    UNION ALL
    SELECT 
        Tenure_Group AS product_tenure_group,
        'Commodities' AS product_name,
        Avg_AmtComm AS product_spending
    FROM tenure_metrics
) pc GROUP BY t.Product, t.Avg_Spending, t.rn

UNION ALL

SELECT
    'Average Purchase Frequency' AS Metric,
    (SELECT Avg_Purchase_Frequency FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 0) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_1,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 1) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_2,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 2) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_3,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 3) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_4,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 4) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_5,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 5) 
        THEN Avg_Purchase_Frequency::text ELSE NULL END) AS Tenure_Group_6
FROM tenure_metrics

UNION ALL

SELECT
    'Average Complaint Rate' AS Metric,
    (SELECT Avg_Complain_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 0) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_1,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 1) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_2,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 2) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_3,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 3) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_4,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 4) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_5,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 5) 
        THEN Avg_Complain_Rate::text ELSE NULL END) AS Tenure_Group_6
FROM tenure_metrics

UNION ALL

SELECT
    'Average Response Rate' AS Metric,
    (SELECT Avg_Response_Rate FROM global_metrics)::text AS Global,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 0) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_1,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 1) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_2,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 2) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_3,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 3) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_4,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 4) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_5,
    MAX(CASE WHEN Tenure_Group = (SELECT Tenure_Group FROM tenure_group_list LIMIT 1 OFFSET 5) 
        THEN Avg_Response_Rate::text ELSE NULL END) AS Tenure_Group_6
FROM tenure_metrics;

-- Sample queries to view the results
SELECT * FROM product_analysis_by_country;
SELECT * FROM product_analysis_by_age_group;
SELECT * FROM product_analysis_by_family_size;
SELECT * FROM product_analysis_by_income;
SELECT * FROM product_analysis_by_education;
SELECT * FROM product_analysis_by_tenure;
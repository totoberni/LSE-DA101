-- ========================================================================
-- CUSTOMER DEMOGRAPHICS SQL SCRIPT (REFACTORED)
-- ========================================================================
-- This script creates views for analyzing customer demographics by country
-- with support for both wide format (original) and long format (for Tableau)
-- Uses Common Table Expressions (CTEs) instead of temporary tables
-- ========================================================================

-- Drop existing views to ensure clean recreation
DROP VIEW IF EXISTS deprecated_demogs_by_country CASCADE;
DROP VIEW IF EXISTS demogs_by_country CASCADE;

-- ========================================================================
-- SECTION 1: CREATE THE LONG FORMAT VIEW
-- ========================================================================

CREATE OR REPLACE VIEW demogs_by_country AS
WITH total_counts AS (
    SELECT
        COUNT(CASE WHEN Response = 1 THEN 1 END) AS total_responses,
        COUNT(CASE WHEN Complain = 1 THEN 1 END) AS total_complaints,
        SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + SUM(Facebook_ad) + SUM(Brochure_ad) AS total_ad_conversions
    FROM customer_data_combined
),
country_metrics AS (
    SELECT
        Country,
        ROUND(AVG(2025 - Year_Birth)::numeric, 2) AS Avg_Age,
        ROUND(AVG(1 + Kidhome + Teenhome + 
            CASE 
                WHEN UPPER(Marital_Status) IN ('TOGETHER', 'MARRIED') THEN 1 
                ELSE 0 
            END)::numeric, 2) AS Avg_Family_Size,
        ROUND(AVG(Income_Numeric)::numeric, 2) AS Avg_Income,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 2) AS Avg_Purchase_Frequency,
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        ROUND(100.0 * COUNT(CASE WHEN Response = 1 THEN 1 END) / 
            (SELECT NULLIF(total_responses, 0) FROM total_counts)::numeric, 2) AS Response_Percentage,
        ROUND(100.0 * COUNT(CASE WHEN Complain = 1 THEN 1 END) / 
            (SELECT NULLIF(total_complaints, 0) FROM total_counts)::numeric, 2) AS Complain_Percentage,
        SUM(Bulkmail_ad) AS Total_Bulkmail_Conversions,
        SUM(Twitter_ad) AS Total_Twitter_Conversions,
        SUM(Instagram_ad) AS Total_Instagram_Conversions,
        SUM(Facebook_ad) AS Total_Facebook_Conversions,
        SUM(Brochure_ad) AS Total_Brochure_Conversions,
        SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + 
            SUM(Facebook_ad) + SUM(Brochure_ad) AS Country_Total_Ad_Conversions,
        ROUND(100.0 * (SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + 
            SUM(Facebook_ad) + SUM(Brochure_ad)) / 
            (SELECT NULLIF(total_ad_conversions, 0) FROM total_counts)::numeric, 2) AS Total_Ad_Percentage,
        COUNT(*) AS Country_Customer_Count
    FROM customer_data_combined
    GROUP BY Country
),
channel_rankings AS (
    SELECT
        Country,
        ROUND(100.0 * Total_Bulkmail_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Bulkmail_Pct,
        ROUND(100.0 * Total_Twitter_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Twitter_Pct,
        ROUND(100.0 * Total_Instagram_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Instagram_Pct,
        ROUND(100.0 * Total_Facebook_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Facebook_Pct,
        ROUND(100.0 * Total_Brochure_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Brochure_Pct,
        (SELECT string_agg(channel || ' (' || percentage || '%)', ', ' ORDER BY percentage DESC, channel)
         FROM (
             SELECT 'Bulkmail' AS channel, 
                ROUND(100.0 * Total_Bulkmail_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS percentage
             WHERE Total_Bulkmail_Conversions > 0
             UNION ALL
             SELECT 'Twitter' AS channel, 
                ROUND(100.0 * Total_Twitter_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS percentage
             WHERE Total_Twitter_Conversions > 0
             UNION ALL
             SELECT 'Instagram' AS channel, 
                ROUND(100.0 * Total_Instagram_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS percentage
             WHERE Total_Instagram_Conversions > 0
             UNION ALL
             SELECT 'Facebook' AS channel, 
                ROUND(100.0 * Total_Facebook_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS percentage
             WHERE Total_Facebook_Conversions > 0
             UNION ALL
             SELECT 'Brochure' AS channel, 
                ROUND(100.0 * Total_Brochure_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS percentage
             WHERE Total_Brochure_Conversions > 0
             ORDER BY percentage DESC
             LIMIT 3
         ) ranked_channels
        ) AS Top_Three_Channels
    FROM country_metrics
),
metrics_union AS (
    -- Avg_Age
    SELECT 
        'Avg_Age' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_Age::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_Family_Size
    SELECT 
        'Avg_Family_Size' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_Family_Size::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_Income
    SELECT 
        'Avg_Income' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_Income::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_Purchase_Frequency
    SELECT 
        'Avg_Purchase_Frequency' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_Purchase_Frequency::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_Total_Spending
    SELECT 
        'Avg_Total_Spending' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_Total_Spending::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtLiq
    SELECT 
        'Avg_AmtLiq' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtLiq::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtVege
    SELECT 
        'Avg_AmtVege' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtVege::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtNonVeg
    SELECT 
        'Avg_AmtNonVeg' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtNonVeg::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtPes
    SELECT 
        'Avg_AmtPes' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtPes::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtChocolates
    SELECT 
        'Avg_AmtChocolates' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtChocolates::text AS value
    FROM country_metrics

    UNION ALL

    -- Avg_AmtComm
    SELECT 
        'Avg_AmtComm' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Avg_AmtComm::text AS value
    FROM country_metrics

    UNION ALL

    -- Response_Percentage
    SELECT 
        'Response_Percentage' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Response_Percentage::text AS value
    FROM country_metrics

    UNION ALL

    -- Complain_Percentage
    SELECT 
        'Complain_Percentage' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Complain_Percentage::text AS value
    FROM country_metrics

    UNION ALL

    -- Total_Ad_Percentage
    SELECT 
        'Total_Ad_Percentage' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Total_Ad_Percentage::text AS value
    FROM country_metrics

    UNION ALL

    -- Top_Three_Channels
    SELECT 
        'Top_Three_Channels' AS metric, 
        Country AS region,
        CASE
            WHEN Country = 'AUS' THEN 'Australia'
            WHEN Country = 'CA' THEN 'Canada'
            WHEN Country = 'GER' THEN 'Germany'
            WHEN Country = 'IND' THEN 'India'
            WHEN Country = 'ME' THEN 'Middle East'
            WHEN Country = 'SA' THEN 'South Africa'
            WHEN Country = 'SP' THEN 'Spain'
            WHEN Country = 'US' THEN 'United States'
            ELSE Country
        END AS region_full_name,
        Top_Three_Channels AS value
    FROM channel_rankings
)
SELECT * FROM metrics_union;

CREATE OR REPLACE VIEW demogs_by_country_tableau AS
WITH base_data AS (
    SELECT * FROM demogs_by_country
    WHERE metric != 'Top_Three_Channels'
),
channel_data AS (
    SELECT
        region,
        region_full_name,
        REGEXP_MATCHES(value, '([A-Za-z]+) \(([0-9.]+)%\)', 'g') AS channel_match
    FROM demogs_by_country
    WHERE metric = 'Top_Three_Channels'
),
extracted_channels AS (
    SELECT
        region,
        region_full_name,
        channel_match[1] AS channel,
        channel_match[2]::numeric AS percentage
    FROM channel_data
)
SELECT
    metric,
    region,
    region_full_name,
    value
FROM base_data

UNION ALL

SELECT
    'Channel_' || channel AS metric,
    region,
    region_full_name,
    percentage::text AS value
FROM extracted_channels;

-- Verify the views
SELECT * FROM demogs_by_country;
SELECT * FROM demogs_by_country_tableau;

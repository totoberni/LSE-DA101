-- Drop the view if it exists before recreating it
DROP VIEW IF EXISTS demogs_by_country CASCADE;

-- Create an enhanced view for demographic analysis by country
CREATE OR REPLACE VIEW demogs_by_country AS
WITH 
-- Calculate total counts for percentage calculations
total_counts AS (
    SELECT
        COUNT(CASE WHEN Response = 1 THEN 1 END) AS total_responses,
        COUNT(CASE WHEN Complain = 1 THEN 1 END) AS total_complaints,
        SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + SUM(Facebook_ad) + SUM(Brochure_ad) AS total_ad_conversions
    FROM customer_data_combined
),
-- Calculate metrics by country
country_metrics AS (
    SELECT
        Country,
        -- Calculate average age based on birth year (current year 2025)
        ROUND(AVG(2025 - Year_Birth)::numeric, 2) AS Avg_Age,
        
        -- Calculate family size (base customer + children + partner)
        ROUND(AVG(1 + Kidhome + Teenhome + 
            CASE 
                WHEN UPPER(Marital_Status) IN ('TOGETHER', 'MARRIED') THEN 1 
                ELSE 0 
            END)::numeric, 2) AS Avg_Family_Size,
            
        -- Average income (using numeric column)
        ROUND(AVG(Income_Numeric)::numeric, 2) AS Avg_Income,
        
        -- Purchase frequency (1/Recency with null handling)
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 2) AS Avg_Purchase_Frequency,
        
        -- Total spending across all categories
        ROUND(AVG(AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm)::numeric, 2) AS Avg_Total_Spending,
        
        -- Individual category spending
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm,
        
        -- Response percentage calculation
        ROUND(100.0 * COUNT(CASE WHEN Response = 1 THEN 1 END) / 
            (SELECT NULLIF(total_responses, 0) FROM total_counts)::numeric, 2) AS Response_Percentage,
            
        -- Complain percentage calculation
        ROUND(100.0 * COUNT(CASE WHEN Complain = 1 THEN 1 END) / 
            (SELECT NULLIF(total_complaints, 0) FROM total_counts)::numeric, 2) AS Complain_Percentage,
            
        -- Ad conversion metrics
        SUM(Bulkmail_ad) AS Total_Bulkmail_Conversions,
        SUM(Twitter_ad) AS Total_Twitter_Conversions,
        SUM(Instagram_ad) AS Total_Instagram_Conversions,
        SUM(Facebook_ad) AS Total_Facebook_Conversions,
        SUM(Brochure_ad) AS Total_Brochure_Conversions,
        
        -- Total ad conversions by country
        SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + 
            SUM(Facebook_ad) + SUM(Brochure_ad) AS Country_Total_Ad_Conversions,
            
        -- Total ad percentage calculation
        ROUND(100.0 * (SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + 
            SUM(Facebook_ad) + SUM(Brochure_ad)) / 
            (SELECT NULLIF(total_ad_conversions, 0) FROM total_counts)::numeric, 2) AS Total_Ad_Percentage,
            
        -- Calculate channel percentages within each country for top 3 determination
        COUNT(*) AS Country_Customer_Count
    FROM customer_data_combined
    GROUP BY Country
),
-- Calculate channel rankings by country
channel_rankings AS (
    SELECT
        Country,
        -- For each country, calculate the percentage of each channel's conversion
        ROUND(100.0 * Total_Bulkmail_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Bulkmail_Pct,
        ROUND(100.0 * Total_Twitter_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Twitter_Pct,
        ROUND(100.0 * Total_Instagram_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Instagram_Pct,
        ROUND(100.0 * Total_Facebook_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Facebook_Pct,
        ROUND(100.0 * Total_Brochure_Conversions / NULLIF(Country_Customer_Count, 0), 2) AS Brochure_Pct,
        
        -- Create a formatted string with the top 3 channels in descending order
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
)
-- Transform the data to have metrics as rows and countries as columns
-- Convert all values to text to ensure type compatibility with UNION operations
SELECT
    'Avg_Age' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Age::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Age::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Age::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Age::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Age::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Age::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Age::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Age::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_Family_Size' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Family_Size::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Family_Size::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Family_Size::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Family_Size::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Family_Size::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Family_Size::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Family_Size::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Family_Size::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_Income' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_Income::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_Income::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_Income::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_Income::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_Income::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_Income::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_Income::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_Income::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_Purchase_Frequency' AS Metric,
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
    'Avg_Total_Spending' AS Metric,
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
    'Avg_AmtLiq' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtLiq::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtLiq::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtLiq::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtLiq::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtLiq::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtLiq::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtLiq::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtLiq::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_AmtVege' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtVege::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtVege::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtVege::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtVege::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtVege::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtVege::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtVege::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtVege::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_AmtNonVeg' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtNonVeg::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtNonVeg::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtNonVeg::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtNonVeg::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtNonVeg::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtNonVeg::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtNonVeg::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtNonVeg::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_AmtPes' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtPes::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtPes::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtPes::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtPes::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtPes::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtPes::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtPes::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtPes::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_AmtChocolates' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtChocolates::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtChocolates::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtChocolates::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtChocolates::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtChocolates::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtChocolates::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtChocolates::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtChocolates::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Avg_AmtComm' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Avg_AmtComm::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Avg_AmtComm::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Avg_AmtComm::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Avg_AmtComm::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Avg_AmtComm::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Avg_AmtComm::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Avg_AmtComm::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Avg_AmtComm::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Response_Percentage' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Response_Percentage::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Response_Percentage::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Response_Percentage::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Response_Percentage::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Response_Percentage::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Response_Percentage::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Response_Percentage::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Response_Percentage::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Complain_Percentage' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Complain_Percentage::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Complain_Percentage::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Complain_Percentage::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Complain_Percentage::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Complain_Percentage::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Complain_Percentage::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Complain_Percentage::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Complain_Percentage::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Total_Ad_Percentage' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Total_Ad_Percentage::text ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Total_Ad_Percentage::text ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Total_Ad_Percentage::text ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Total_Ad_Percentage::text ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Total_Ad_Percentage::text ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Total_Ad_Percentage::text ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Total_Ad_Percentage::text ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Total_Ad_Percentage::text ELSE NULL END) AS US
FROM country_metrics

UNION ALL

SELECT
    'Top_Three_Channels' AS Metric,
    MAX(CASE WHEN Country = 'AUS' THEN Top_Three_Channels ELSE NULL END) AS AUS,
    MAX(CASE WHEN Country = 'CA' THEN Top_Three_Channels ELSE NULL END) AS CA,
    MAX(CASE WHEN Country = 'GER' THEN Top_Three_Channels ELSE NULL END) AS GER,
    MAX(CASE WHEN Country = 'IND' THEN Top_Three_Channels ELSE NULL END) AS IND,
    MAX(CASE WHEN Country = 'ME' THEN Top_Three_Channels ELSE NULL END) AS ME,
    MAX(CASE WHEN Country = 'SA' THEN Top_Three_Channels ELSE NULL END) AS SA,
    MAX(CASE WHEN Country = 'SP' THEN Top_Three_Channels ELSE NULL END) AS SP,
    MAX(CASE WHEN Country = 'US' THEN Top_Three_Channels ELSE NULL END) AS US
FROM channel_rankings;

-- Command to view the new table structure
SELECT * FROM demogs_by_country;
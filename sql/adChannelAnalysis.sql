-- ========================================================================
-- Table 1: Ad Channel Conversion Analysis
-- ========================================================================
DROP VIEW IF EXISTS ad_channel_conversion_analysis CASCADE;

CREATE OR REPLACE VIEW ad_channel_conversion_analysis AS
WITH 
-- Calculate total customers for percentage calculations
total_customers AS (
    SELECT COUNT(*) AS count FROM customer_data_combined),
-- Calculate global conversion metrics for each ad channel
channel_conversions AS (
    SELECT
        -- Global counts for each channel
        SUM(Bulkmail_ad) AS Total_Bulkmail_Conversions,
        SUM(Twitter_ad) AS Total_Twitter_Conversions,
        SUM(Instagram_ad) AS Total_Instagram_Conversions,
        SUM(Facebook_ad) AS Total_Facebook_Conversions,
        SUM(Brochure_ad) AS Total_Brochure_Conversions,
        
        -- Total conversions across all channels
        SUM(Bulkmail_ad) + SUM(Twitter_ad) + SUM(Instagram_ad) + 
        SUM(Facebook_ad) + SUM(Brochure_ad) AS Total_All_Conversions,
        
        -- Calculate customer count
        COUNT(*) AS Total_Customers,
        
        -- Calculate averages per customer (indicates customers with multiple channel conversions)
        ROUND(AVG(Bulkmail_ad + Twitter_ad + Instagram_ad + Facebook_ad + Brochure_ad)::numeric, 2) AS Avg_Channels_Per_Customer
    FROM customer_data_combined),
-- Calculate conversion percentages 
conversion_percentages AS (
    SELECT
        -- Channel conversion percentages relative to total customers
        ROUND(100.0 * Total_Bulkmail_Conversions / Total_Customers::numeric, 2) AS Bulkmail_Conversion_Pct,
        ROUND(100.0 * Total_Twitter_Conversions / Total_Customers::numeric, 2) AS Twitter_Conversion_Pct,
        ROUND(100.0 * Total_Instagram_Conversions / Total_Customers::numeric, 2) AS Instagram_Conversion_Pct,
        ROUND(100.0 * Total_Facebook_Conversions / Total_Customers::numeric, 2) AS Facebook_Conversion_Pct,
        ROUND(100.0 * Total_Brochure_Conversions / Total_Customers::numeric, 2) AS Brochure_Conversion_Pct,
        
        -- Overall conversion percentage across all channels
        ROUND(100.0 * Total_All_Conversions / Total_Customers::numeric, 2) AS All_Channels_Conversion_Pct,
        
        -- Relative contribution of each channel to total conversions
        ROUND(100.0 * Total_Bulkmail_Conversions / NULLIF(Total_All_Conversions, 0)::numeric, 2) AS Bulkmail_Share_Pct,
        ROUND(100.0 * Total_Twitter_Conversions / NULLIF(Total_All_Conversions, 0)::numeric, 2) AS Twitter_Share_Pct,
        ROUND(100.0 * Total_Instagram_Conversions / NULLIF(Total_All_Conversions, 0)::numeric, 2) AS Instagram_Share_Pct,
        ROUND(100.0 * Total_Facebook_Conversions / NULLIF(Total_All_Conversions, 0)::numeric, 2) AS Facebook_Share_Pct,
        ROUND(100.0 * Total_Brochure_Conversions / NULLIF(Total_All_Conversions, 0)::numeric, 2) AS Brochure_Share_Pct
    FROM channel_conversions
),
-- Calculate product affinities by channel
product_by_channel AS (
    -- Bulkmail channel product affinities
    SELECT 
        'Bulkmail' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Bulkmail_ad = 1
    
    UNION ALL
    
    -- Twitter channel product affinities
    SELECT 
        'Twitter' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Twitter_ad = 1
    
    UNION ALL
    
    -- Instagram channel product affinities
    SELECT 
        'Instagram' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Instagram_ad = 1
    
    UNION ALL
    
    -- Facebook channel product affinities
    SELECT 
        'Facebook' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Facebook_ad = 1
    
    UNION ALL
    
    -- Brochure channel product affinities
    SELECT 
        'Brochure' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Brochure_ad = 1
    
    UNION ALL
    
    -- All customers (for comparison)
    SELECT 
        'All Customers' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
),
-- Calculate top 3 products by channel
top_products_by_channel AS (
    SELECT
        Channel,
        (SELECT string_agg(product || ' ($' || amount || ')', ', ' ORDER BY amount DESC, product)
         FROM (
            SELECT 'Alcohol' AS product, Avg_AmtLiq AS amount WHERE Avg_AmtLiq > 0
            UNION ALL SELECT 'Vegetables' AS product, Avg_AmtVege AS amount WHERE Avg_AmtVege > 0
            UNION ALL SELECT 'Meat' AS product, Avg_AmtNonVeg AS amount WHERE Avg_AmtNonVeg > 0
            UNION ALL SELECT 'Fish' AS product, Avg_AmtPes AS amount WHERE Avg_AmtPes > 0
            UNION ALL SELECT 'Chocolates' AS product, Avg_AmtChocolates AS amount WHERE Avg_AmtChocolates > 0
            UNION ALL SELECT 'Commodities' AS product, Avg_AmtComm AS amount WHERE Avg_AmtComm > 0
            ORDER BY amount DESC
            LIMIT 3
         ) ranked_products
        ) AS Top_Three_Products
    FROM product_by_channel
)
-- Build the final analysis table
SELECT 
    'Global_Conversion_Rates' AS Metric,
    Bulkmail_Conversion_Pct AS Bulkmail_Ad,
    Twitter_Conversion_Pct AS Twitter_Ad,
    Instagram_Conversion_Pct AS Instagram_Ad,
    Facebook_Conversion_Pct AS Facebook_Ad,
    Brochure_Conversion_Pct AS Brochure_Ad,
    All_Channels_Conversion_Pct AS All_Channels
FROM conversion_percentages

UNION ALL

SELECT 
    'Channel_Share_of_Conversions' AS Metric,
    Bulkmail_Share_Pct AS Bulkmail_Ad,
    Twitter_Share_Pct AS Twitter_Ad,
    Instagram_Share_Pct AS Instagram_Ad,
    Facebook_Share_Pct AS Facebook_Ad,
    Brochure_Share_Pct AS Brochure_Ad,
    100 AS All_Channels
FROM conversion_percentages;

-- Create the product affinity analysis view
-- Create a long-format view for Tableau visualization
DROP VIEW IF EXISTS ad_channel_product_affinity_tableau CASCADE;

CREATE OR REPLACE VIEW ad_channel_product_affinity_tableau AS
WITH 
-- Calculate product affinities by channel
product_by_channel AS (
    -- Bulkmail channel product affinities
    SELECT 
        'Bulkmail' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Bulkmail_ad = 1
    
    UNION ALL
    
    -- Twitter channel product affinities
    SELECT 
        'Twitter' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Twitter_ad = 1
    
    UNION ALL
    
    -- Instagram channel product affinities
    SELECT 
        'Instagram' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Instagram_ad = 1
    
    UNION ALL
    
    -- Facebook channel product affinities
    SELECT 
        'Facebook' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Facebook_ad = 1
    
    UNION ALL
    
    -- Brochure channel product affinities
    SELECT 
        'Brochure' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Brochure_ad = 1
    
    UNION ALL
    
    -- No specific channel (control group for comparison)
    SELECT 
        'No Channel' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
    WHERE Bulkmail_ad = 0 AND Twitter_ad = 0 AND Instagram_ad = 0 AND Facebook_ad = 0 AND Brochure_ad = 0
    
    UNION ALL
    
    -- All customers (global average)
    SELECT 
        'All Customers' AS Channel,
        ROUND(AVG(AmtLiq)::numeric, 2) AS Avg_AmtLiq,
        ROUND(AVG(AmtVege)::numeric, 2) AS Avg_AmtVege,
        ROUND(AVG(AmtNonVeg)::numeric, 2) AS Avg_AmtNonVeg,
        ROUND(AVG(AmtPes)::numeric, 2) AS Avg_AmtPes,
        ROUND(AVG(AmtChocolates)::numeric, 2) AS Avg_AmtChocolates,
        ROUND(AVG(AmtComm)::numeric, 2) AS Avg_AmtComm
    FROM customer_data_combined
),
-- Calculate channel display order for consistent sorting
channel_order AS (
    SELECT 
        Channel,
        CASE 
            WHEN Channel = 'All Customers' THEN 1
            WHEN Channel = 'No Channel' THEN 2
            ELSE 3
        END AS Sort_Order
    FROM product_by_channel
),
-- Calculate top 3 products by channel with formatting (keeping for reference)
top_products_by_channel AS (
    SELECT
        Channel,
        (SELECT string_agg(product || ' ($' || amount || ')', ', ' ORDER BY amount DESC)
         FROM (
             SELECT 'Alcohol' AS product, Avg_AmtLiq AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtLiq > 0
             
             UNION ALL 
             
             SELECT 'Vegetables' AS product, Avg_AmtVege AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtVege > 0
             
             UNION ALL 
             
             SELECT 'Meat' AS product, Avg_AmtNonVeg AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtNonVeg > 0
             
             UNION ALL 
             
             SELECT 'Fish' AS product, Avg_AmtPes AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtPes > 0
             
             UNION ALL 
             
             SELECT 'Chocolates' AS product, Avg_AmtChocolates AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtChocolates > 0
             
             UNION ALL 
             
             SELECT 'Commodities' AS product, Avg_AmtComm AS amount 
             FROM product_by_channel p2 
             WHERE p2.Channel = product_by_channel.Channel AND Avg_AmtComm > 0
             
             ORDER BY amount DESC
             LIMIT 3
         ) ranked_products
        ) AS Top_Three_Products
    FROM product_by_channel
),
-- Get channel product rankings (for tooltips and analysis)
product_rankings AS (
    SELECT 
        Channel,
        'Alcohol' AS Product,
        Avg_AmtLiq AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtLiq DESC) AS Rank
    FROM product_by_channel
    
    UNION ALL
    
    SELECT 
        Channel,
        'Vegetables' AS Product,
        Avg_AmtVege AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtVege DESC) AS Rank
    FROM product_by_channel
    
    UNION ALL
    
    SELECT 
        Channel,
        'Meat' AS Product,
        Avg_AmtNonVeg AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtNonVeg DESC) AS Rank
    FROM product_by_channel
    
    UNION ALL
    
    SELECT 
        Channel,
        'Fish' AS Product,
        Avg_AmtPes AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtPes DESC) AS Rank
    FROM product_by_channel
    
    UNION ALL
    
    SELECT 
        Channel,
        'Chocolates' AS Product,
        Avg_AmtChocolates AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtChocolates DESC) AS Rank
    FROM product_by_channel
    
    UNION ALL
    
    SELECT 
        Channel,
        'Commodities' AS Product,
        Avg_AmtComm AS Amount,
        RANK() OVER(PARTITION BY Channel ORDER BY Avg_AmtComm DESC) AS Rank
    FROM product_by_channel
),
-- Convert to long format for Tableau
long_format AS (
    -- Alcohol spending by channel
    SELECT
        p.Channel,
        'Alcohol' AS Product_Category,
        p.Avg_AmtLiq AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Alcohol'
    
    UNION ALL
    
    -- Vegetables spending by channel
    SELECT
        p.Channel,
        'Vegetables' AS Product_Category,
        p.Avg_AmtVege AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Vegetables'
    
    UNION ALL
    
    -- Meat spending by channel
    SELECT
        p.Channel,
        'Meat' AS Product_Category,
        p.Avg_AmtNonVeg AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Meat'
    
    UNION ALL
    
    -- Fish spending by channel
    SELECT
        p.Channel,
        'Fish' AS Product_Category,
        p.Avg_AmtPes AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Fish'
    
    UNION ALL
    
    -- Chocolates spending by channel
    SELECT
        p.Channel,
        'Chocolates' AS Product_Category,
        p.Avg_AmtChocolates AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Chocolates'
    
    UNION ALL
    
    -- Commodities spending by channel
    SELECT
        p.Channel,
        'Commodities' AS Product_Category,
        p.Avg_AmtComm AS Average_Spending,
        r.Rank AS Product_Rank,
        o.Sort_Order,
        t.Top_Three_Products
    FROM product_by_channel p
    JOIN channel_order o ON p.Channel = o.Channel
    JOIN top_products_by_channel t ON p.Channel = t.Channel
    JOIN product_rankings r ON p.Channel = r.Channel AND r.Product = 'Commodities'
)
-- Final Tableau view with all needed metrics
SELECT
    Channel,
    Product_Category,
    Average_Spending,
    CASE WHEN Product_Rank <= 3 THEN TRUE ELSE FALSE END AS Is_Top_Three_Product,
    Product_Rank,
    Top_Three_Products,
    -- Calculate global average (All Customers) for each product
    FIRST_VALUE(Average_Spending) OVER (
        PARTITION BY Product_Category 
        ORDER BY CASE WHEN Channel = 'All Customers' THEN 0 ELSE 1 END
    ) AS Global_Average,
    -- Calculate percentage difference from global average
    ROUND(
        (Average_Spending - FIRST_VALUE(Average_Spending) OVER (
            PARTITION BY Product_Category 
            ORDER BY CASE WHEN Channel = 'All Customers' THEN 0 ELSE 1 END
        )) / NULLIF(FIRST_VALUE(Average_Spending) OVER (
            PARTITION BY Product_Category 
            ORDER BY CASE WHEN Channel = 'All Customers' THEN 0 ELSE 1 END
        ), 0) * 100,
        2
    ) AS Pct_Diff_From_Global_Avg
FROM 
    long_format
ORDER BY 
    Sort_Order,
    Channel,
    Average_Spending DESC;

-- ========================================================================
-- Table 2: Revenue Analysis by Channel
-- ========================================================================
DROP VIEW IF EXISTS ad_channel_revenue_analysis CASCADE;

CREATE OR REPLACE VIEW ad_channel_revenue_analysis AS
WITH 
-- Calculate total spending for each customer
customer_spend AS (
    SELECT
        ID,
        (AmtLiq + AmtVege + AmtNonVeg + AmtPes + AmtChocolates + AmtComm) AS Total_Spend,
        Bulkmail_ad,
        Twitter_ad,
        Instagram_ad,
        Facebook_ad,
        Brochure_ad
    FROM customer_data_combined
),
-- Calculate global total spending for normalization
global_spend AS (
    SELECT SUM(Total_Spend) AS Global_Total_Spend
    FROM customer_spend
),
-- Calculate revenue metrics by channel
channel_revenue AS (
    -- Bulkmail channel revenue
    SELECT
        'Bulkmail' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Bulkmail_ad = 1
    
    UNION ALL
    
    -- Twitter channel revenue
    SELECT
        'Twitter' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Twitter_ad = 1
    
    UNION ALL
    
    -- Instagram channel revenue
    SELECT
        'Instagram' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Instagram_ad = 1
    
    UNION ALL
    
    -- Facebook channel revenue
    SELECT
        'Facebook' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Facebook_ad = 1
    
    UNION ALL
    
    -- Brochure channel revenue
    SELECT
        'Brochure' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Brochure_ad = 1
    
    UNION ALL
    
    -- No specific channel (control group)
    SELECT
        'No Channel' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Bulkmail_ad = 0 AND Twitter_ad = 0 AND Instagram_ad = 0 
        AND Facebook_ad = 0 AND Brochure_ad = 0
    
    UNION ALL
    
    -- All channels combined (all customers with any ad conversion)
    SELECT
        'All Ad Channels' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
    WHERE Bulkmail_ad = 1 OR Twitter_ad = 1 OR Instagram_ad = 1 
        OR Facebook_ad = 1 OR Brochure_ad = 1
    
    UNION ALL
    
    -- Global average (all customers)
    SELECT
        'All Customers' AS Channel,
        SUM(Total_Spend) AS Channel_Total_Revenue,
        ROUND(AVG(Total_Spend)::numeric, 2) AS Channel_Avg_Revenue_Per_Customer,
        COUNT(*) AS Channel_Customer_Count
    FROM customer_spend
)
-- Calculate revenue share percentages
SELECT
    Channel,
    Channel_Total_Revenue,
    Channel_Avg_Revenue_Per_Customer,
    Channel_Customer_Count,
    ROUND(100.0 * Channel_Total_Revenue / 
        (SELECT Global_Total_Spend FROM global_spend)::numeric, 2) AS Pct_of_Total_Revenue,
    -- Revenue per customer relative to global average
    ROUND(100.0 * Channel_Avg_Revenue_Per_Customer / 
        (SELECT Channel_Avg_Revenue_Per_Customer FROM channel_revenue WHERE Channel = 'All Customers')::numeric, 2) 
        AS Pct_of_Avg_Customer_Revenue
FROM 
    channel_revenue
ORDER BY 
    CASE 
        WHEN Channel = 'All Customers' THEN 1
        WHEN Channel = 'All Ad Channels' THEN 2
        WHEN Channel = 'No Channel' THEN 3
        ELSE 4
    END,
    Channel_Total_Revenue DESC;

	-- ========================================================================
-- Table 3: Customer Behavior Analysis by Channel
-- ========================================================================
DROP VIEW IF EXISTS ad_channel_behavior_analysis CASCADE;

CREATE OR REPLACE VIEW ad_channel_behavior_analysis AS
WITH 
-- Calculate behavior metrics by channel
channel_behavior AS (
    -- Bulkmail channel behavior
    SELECT
        'Bulkmail' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Bulkmail_ad = 1
    
    UNION ALL
    
    -- Twitter channel behavior
    SELECT
        'Twitter' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Twitter_ad = 1
    
    UNION ALL
    
    -- Instagram channel behavior
    SELECT
        'Instagram' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Instagram_ad = 1
    
    UNION ALL
    
    -- Facebook channel behavior
    SELECT
        'Facebook' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Facebook_ad = 1
    
    UNION ALL
    
    -- Brochure channel behavior
    SELECT
        'Brochure' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Brochure_ad = 1
    
    UNION ALL
    
    -- No specific channel (control group)
    SELECT
        'No Channel' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Bulkmail_ad = 0 AND Twitter_ad = 0 AND Instagram_ad = 0 
        AND Facebook_ad = 0 AND Brochure_ad = 0
    
    UNION ALL
    
    -- All channels combined (all customers with any ad conversion)
    SELECT
        'All Ad Channels' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
    WHERE Bulkmail_ad = 1 OR Twitter_ad = 1 OR Instagram_ad = 1 
        OR Facebook_ad = 1 OR Brochure_ad = 1
    
    UNION ALL
    
    -- Global average (all customers)
    SELECT
        'All Customers' AS Channel,
        ROUND(AVG(CASE WHEN Recency = 0 THEN NULL ELSE 1.0/Recency END)::numeric, 4) AS Avg_Purchase_Frequency,
        ROUND(AVG(NumVisits)::numeric, 2) AS Avg_NumVisits,
        ROUND(AVG(NumWebBuy)::numeric, 2) AS Avg_NumWebBuy,
        ROUND(AVG(NumDeals)::numeric, 2) AS Avg_NumDeals,
        ROUND(AVG(Response)::numeric, 2) AS Avg_Response,
        ROUND(AVG(NumWalkinPur)::numeric, 2) AS Avg_NumWalkinPur,
        ROUND(AVG(Complain)::numeric, 2) AS Avg_Complain,
        COUNT(*) AS Customer_Count
    FROM customer_data_combined
)
-- Calculate relative performance compared to all customers (global average)
SELECT
    c.Channel,
    c.Avg_Purchase_Frequency,
    c.Avg_NumVisits,
    c.Avg_NumWebBuy,
    c.Avg_NumDeals,
    c.Avg_Response,
    c.Avg_NumWalkinPur,
    c.Avg_Complain,
    c.Customer_Count,
    -- Relative metrics compared to global average
    ROUND(100.0 * c.Avg_Purchase_Frequency / NULLIF(g.Avg_Purchase_Frequency, 0)::numeric, 2) AS Rel_Purchase_Frequency,
    ROUND(100.0 * c.Avg_NumVisits / NULLIF(g.Avg_NumVisits, 0)::numeric, 2) AS Rel_NumVisits,
    ROUND(100.0 * c.Avg_NumWebBuy / NULLIF(g.Avg_NumWebBuy, 0)::numeric, 2) AS Rel_NumWebBuy,
    ROUND(100.0 * c.Avg_NumDeals / NULLIF(g.Avg_NumDeals, 0)::numeric, 2) AS Rel_NumDeals,
    ROUND(100.0 * c.Avg_Response / NULLIF(g.Avg_Response, 0)::numeric, 2) AS Rel_Response,
    ROUND(100.0 * c.Avg_NumWalkinPur / NULLIF(g.Avg_NumWalkinPur, 0)::numeric, 2) AS Rel_NumWalkinPur,
    ROUND(100.0 * c.Avg_Complain / NULLIF(g.Avg_Complain, 0)::numeric, 2) AS Rel_Complain
FROM 
    channel_behavior c
CROSS JOIN
    (SELECT * FROM channel_behavior WHERE Channel = 'All Customers') g
ORDER BY 
    CASE 
        WHEN c.Channel = 'All Customers' THEN 1
        WHEN c.Channel = 'All Ad Channels' THEN 2
        WHEN c.Channel = 'No Channel' THEN 3
        ELSE 4
    END,
    c.Avg_Purchase_Frequency DESC;

CREATE OR REPLACE VIEW miao AS
WITH global_rates AS (
    SELECT
        'bulkmail_ad' AS channel,
        bulkmail_ad AS global_conversion_rate
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Global_Conversion_Rates'
    
    UNION ALL
    
    SELECT
        'twitter_ad' AS channel,
        twitter_ad AS global_conversion_rate
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Global_Conversion_Rates'
    
    UNION ALL
    
    SELECT
        'instagram_ad' AS channel,
        instagram_ad AS global_conversion_rate
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Global_Conversion_Rates'
    
    UNION ALL
    
    SELECT
        'facebook_ad' AS channel,
        facebook_ad AS global_conversion_rate
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Global_Conversion_Rates'
    
    UNION ALL
    
    SELECT
        'brochure_ad' AS channel,
        brochure_ad AS global_conversion_rate
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Global_Conversion_Rates'
),
share_rates AS (
    SELECT
        'bulkmail_ad' AS channel,
        bulkmail_ad AS channel_share
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Channel_Share_of_Conversions'
    
    UNION ALL
    
    SELECT
        'twitter_ad' AS channel,
        twitter_ad AS channel_share
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Channel_Share_of_Conversions'
    
    UNION ALL
    
    SELECT
        'instagram_ad' AS channel,
        instagram_ad AS channel_share
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Channel_Share_of_Conversions'
    
    UNION ALL
    
    SELECT
        'facebook_ad' AS channel,
        facebook_ad AS channel_share
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Channel_Share_of_Conversions'
    
    UNION ALL
    
    SELECT
        'brochure_ad' AS channel,
        brochure_ad AS channel_share
    FROM ad_channel_conversion_analysis
    WHERE metric = 'Channel_Share_of_Conversions'
)
SELECT
    g.channel,
    g.global_conversion_rate,
    s.channel_share,
    (SELECT all_channels FROM ad_channel_conversion_analysis WHERE metric = 'Global_Conversion_Rates' LIMIT 1) AS all_channels_global,
    (SELECT all_channels FROM ad_channel_conversion_analysis WHERE metric = 'Channel_Share_of_Conversions' LIMIT 1) AS all_channels_share
FROM
    global_rates g
JOIN
    share_rates s ON g.channel = s.channel;

-- ========================================================================
-- Sample queries to test the views (and the vibes)
-- ========================================================================

-- View the conversion analysis results
SELECT * FROM ad_channel_conversion_analysis;

SELECT * FROM miao;

-- View product affinity results
SELECT * FROM ad_channel_product_affinity_tableau;

-- View the revenue analysis results
SELECT * FROM ad_channel_revenue_analysis;

-- View the behavior analysis results
SELECT * FROM ad_channel_behavior_analysis;
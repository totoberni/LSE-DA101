-- Create a single joined table for analysis
DROP TABLE IF EXISTS customer_data_combined CASCADE;

-- Create the combined table with all columns from both source tables
CREATE TABLE customer_data_combined AS 
SELECT 
    m.ID,
    m.Year_Birth,
    m.Education,
    m.Marital_Status,
    m.Income,
    m.Kidhome,
    m.Teenhome,
    m.Dt_Customer,
    m.Recency,
    m.AmtLiq,
    m.AmtVege,
    m.AmtNonVeg,
    m.AmtPes,
    m.AmtChocolates,
    m.AmtComm,
    m.NumDeals,
    m.NumWebBuy,
    m.NumWalkinPur,
    m.NumVisits,
    m.Response,
    m.Complain,
    m.Country,
    m.Count_success,
    NULL::DATE AS Customer_Date,
    NULL::NUMERIC AS Income_Numeric,
    a.Bulkmail_ad,
    a.Twitter_ad,
    a.Instagram_ad,
    a.Facebook_ad,
    a.Brochure_ad
FROM 
    marketing_data m
LEFT JOIN 
    ad_data a ON m.ID = a.ID;

-- Convert the string dates to proper date format
UPDATE customer_data_combined 
SET Customer_Date = TO_DATE(Dt_Customer, 'MM/DD/YY');

-- Convert income strings to numeric values
UPDATE customer_data_combined 
SET Income_Numeric = REPLACE(REPLACE(Income, '$', ''), ',', '')::NUMERIC;

-- Add primary key constraint
ALTER TABLE customer_data_combined ADD PRIMARY KEY (ID);

-- Verify the new table
SELECT * FROM customer_data_combined LIMIT 15;
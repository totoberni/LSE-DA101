-- Creating Tables for Data Analyis
-- Drop tables if they exist (optional, for clean restart)
DROP TABLE IF EXISTS marketing_data CASCADE;
DROP TABLE IF EXISTS ad_data CASCADE;

-- Create marketing_data table with appropriate data types
CREATE TABLE IF NOT EXISTS marketing_data (
    ID INTEGER PRIMARY KEY,
    Year_Birth INTEGER,
    Education VARCHAR(20),
    Marital_Status VARCHAR(20),
    Income VARCHAR(20),  -- Keep as VARCHAR to handle $ and commas
    Kidhome INTEGER,
    Teenhome INTEGER,
    Dt_Customer VARCHAR(10),  -- Store as string initially due to format variations
    Recency INTEGER,
    AmtLiq INTEGER,
    AmtVege INTEGER,
    AmtNonVeg INTEGER,
    AmtPes INTEGER,
    AmtChocolates INTEGER,
    AmtComm INTEGER,
    NumDeals INTEGER,
    NumWebBuy INTEGER,
    NumWalkinPur INTEGER,
    NumVisits INTEGER,
    Response INTEGER,
    Complain INTEGER,
    Country VARCHAR(3),
    Count_success INTEGER
);

-- Create ad_data table
CREATE TABLE IF NOT EXISTS ad_data (
    ID INTEGER PRIMARY KEY,
    Bulkmail_ad INTEGER,
    Twitter_ad INTEGER,
    Instagram_ad INTEGER,
    Facebook_ad INTEGER,
    Brochure_ad INTEGER
);


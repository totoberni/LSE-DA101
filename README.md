# 2Market Data Analysis Project

## Table of Contents
- [Project Overview](#project-overview)
- [Project Structure](#project-structure)
- [Quick Start Guide](#quick-start-guide)
- [Database Setup Process](#database-setup-process)
- [Data Tables Overview](#data-tables-overview)
- [Tableau-Ready Views](#tableau-ready-views)
- [Key Features](#key-features)

## Project Overview

This PostgreSQL project processes and analyzes marketing and ad conversion data for 2Market. The analysis helps the company understand:

1. The demographics of their customers
2. Which advertising channels are most effective
3. Which products sell best and how sales vary based on demographics

## Project Structure

```
LSE-DA101/                          # Project root directory
│
├── data/                           # Raw data files
│   ├── ad_data.csv                 # Marketing channel conversion data (35KB)
│   ├── marketing_data.csv          # Customer demographic and purchase data (199KB)
│   └── metadata_2Market.txt        # Data dictionary and field descriptions (3.1KB)
│
├── sql/                            # SQL scripts for data processing and analysis
│   ├── tableMaking.sql             # Creates initial database tables
│   ├── tableDataCleaning.sql       # Joins and cleans the data
│   ├── customerDemographics.sql    # Customer demographic analysis
│   ├── adChannelAnalysis.sql       # Ad channel effectiveness analysis
│   └── productDemographics.sql     # Product preferences by demographic
│
├── tableau/                        # Tableau visualization files
│   └── M2MBook.twb                 # Main Tableau workbook with all visualizations
│
├── reports/                        # Project documentation and reports
│   ├── main_report.tex             # LaTeX source for the main report
│   ├── LSE-DA101 Report.pdf        # Final compiled report (PDF)
│   └── README.pdf                  # PDF version of this README
│
├── video/                          # Video presentation
│   └── 2Market Business Analysis.mp4  # Video walkthrough of the analysis (37MB)
│
└── README.md                       # This file - project documentation
```

### Directory Descriptions

- **`data/`**: Contains all raw data files used in the analysis
  - CSV files with customer and advertising data
  - Metadata file explaining data fields and their meanings

- **`sql/`**: Contains all SQL scripts in execution order
  - Scripts are numbered implicitly by their logical execution sequence
  - Each script builds upon the previous ones

- **`tableau/`**: Contains the Tableau workbook
  - Connects to the PostgreSQL views created by the SQL scripts
  - Contains all visualizations referenced in the report

- **`reports/`**: Contains all project documentation
  - LaTeX source file for academic formatting
  - Final PDF report with complete analysis
  - PDF version of this README for offline reference

- **`video/`**: Contains the video presentation
  - MP4 format video explaining the key findings
  - Demonstrates the Tableau dashboard in action

## Quick Start Guide

1. **Review the data**: Check `data/metadata_2Market.txt` for field descriptions
2. **Set up the database**: Follow the [Database Setup Process](#database-setup-process)
3. **View the analysis**: Open `reports/LSE-DA101 Report.pdf`
4. **Explore visualizations**: Open `tableau/M2MBook.twb` in Tableau
5. **Watch the presentation**: View `video/2Market Business Analysis.mp4`

## Database Setup Process

```
1. Create database on pgAdmin 
2. Run tableMaking.sql to create tables
3. Run tableDataCleaning.sql to create a single joined table
4. Run customerDemographics.sql to analyze customer demographics
5. Run adChannelAnalysis.sql to evaluate advertising channel effectiveness
6. Run productDemographics.sql to analyze product preferences by demographic
```

## Data Tables Overview

The project starts with two data source tables and creates a combined analysis table:

```
┌───────────────────┐           ┌───────────────────┐
│  marketing_data   │           │     ad_data       │
├───────────────────┤           ├───────────────────┤
│ ID (PK)           │           │ ID (PK)           │
│ Year_Birth        │           │ Bulkmail_ad       │
│ Education         │           │ Twitter_ad        │
│ Marital_Status    │           │ Instagram_ad      │
│ Income            │           │ Facebook_ad       │
│ Kidhome           │           │ Brochure_ad       │
│ Teenhome          │           │                   │
│ ... (and more)    │           │                   │
└───────────────────┘           └───────────────────┘
              \                  /
               \                /
                \              /
                 \            /
                  ▼          ▼
           ┌───────────────────────────┐
           │   customer_data_combined  │
           ├───────────────────────────┤
           │ ID (PK)                   │
           │ Year_Birth                │
           │ Education                 │
           │ ... (many columns)        │
           │ Customer_Date (derived)   │
           │ Income_Numeric (derived)  │
           └───────────────────────────┘
```

## Tableau-Ready Views

The following views are specifically designed for visualization in Tableau:

### 1. Customer Demographics (customerDemographics.sql)

```
┌─────────────────────────────┐
│ demogs_by_country_tableau   │
├─────────────────────────────┤
│ metric                      │
│ region                      │
│ region_full_name            │
│ value                       │
└─────────────────────────────┘
```

This long-format view transforms the wide-format country data into a structure optimized for Tableau visualizations. It includes expanded country names and formatted metric values.

### 2. Ad Channel Analysis (adChannelAnalysis.sql)

Several Tableau-optimized views are available:

```
┌────────────────────────────────┐
│ ad_channel_conversion_tableau  │
├────────────────────────────────┤
│ channel                        │
│ global_conversion_rate         │
│ channel_share                  │
│ all_channels_global            │
│ all_channels_share             │
└────────────────────────────────┘

┌────────────────────────────────┐
│ ad_channel_product_affinity_   │
│ tableau                        │
├────────────────────────────────┤
│ channel                        │
│ product_category               │
│ average_spending               │
│ is_top_three_product           │
│ product_rank                   │
│ top_three_products             │
│ global_average                 │
│ pct_diff_from_global_avg       │
└────────────────────────────────┘

┌────────────────────────────────┐
│ ad_channel_revenue_analysis    │
├────────────────────────────────┤
│ channel                        │
│ channel_total_revenue          │
│ channel_avg_revenue_per_       │
│ customer                       │
│ channel_customer_count         │
│ pct_of_total_revenue           │
│ pct_of_avg_customer_revenue    │
└────────────────────────────────┘

┌────────────────────────────────┐
│ ad_channel_behavior_tableau    │
├────────────────────────────────┤
│ channel                        │
│ metric                         │
│ avg_value                      │
│ rel_value                      │
│ customer_count                 │
└────────────────────────────────┘
```

The `ad_channel_revenue_analysis` view is directly usable in Tableau without further pivoting.

### 3. Product Demographics Analysis (productDemographics.sql)

```
┌─────────────────────────────────┐
│ product_analysis_by_age_group_  │
│ tableau                         │
├─────────────────────────────────┤
│ metric                          │
│ age_group                       │
│ value                           │
│ metric_category                 │
│ product_name                    │
│ product_rank                    │
│ age_group_order                 │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ product_analysis_by_family_size_│
│ tableau                         │
├─────────────────────────────────┤
│ metric                          │
│ family_size                     │
│ value                           │
│ metric_category                 │
│ product_name                    │
│ product_rank                    │
│ family_size_order               │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ product_analysis_by_income_     │
│ tableau                         │
├─────────────────────────────────┤
│ metric                          │
│ income_bracket                  │
│ value                           │
│ metric_category                 │
│ product_name                    │
│ product_rank                    │
│ income_bracket_order            │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ product_analysis_by_tenure_     │
│ tableau                         │
├─────────────────────────────────┤
│ metric                          │
│ tenure_group                    │
│ value                           │
│ metric_category                 │
│ product_name                    │
│ product_rank                    │
│ tenure_group_order              │
└─────────────────────────────────┘
```

Each of these views is in a long format optimized for Tableau visualizations, with additional derived columns for improved filtering and organization.

## Using the Tableau-Ready Views

### Customer Demographics View

```sql
-- Get all demographic data in Tableau-friendly format
SELECT * FROM demogs_by_country_tableau;

-- Filter for specific metrics
SELECT * FROM demogs_by_country_tableau 
WHERE metric IN ('Avg_Age', 'Avg_Income', 'Response_Percentage');

-- Compare marketing channel data by region
SELECT * FROM demogs_by_country_tableau 
WHERE metric LIKE 'Channel_%';
```

### Ad Channel Analysis Views

```sql
-- View conversion rates across all channels
SELECT * FROM ad_channel_conversion_tableau;

-- Compare product preferences and spending by channel
SELECT * FROM ad_channel_product_affinity_tableau
ORDER BY channel, average_spending DESC;

-- Analyze revenue contribution by channel
SELECT channel, channel_total_revenue, pct_of_total_revenue 
FROM ad_channel_revenue_analysis
WHERE channel NOT IN ('All Customers', 'All Ad Channels', 'No Channel')
ORDER BY pct_of_total_revenue DESC;

-- Examine behavior metrics by channel and metric type
SELECT * FROM ad_channel_behavior_analysis_tableau
WHERE metric = 'Campaign Response'
ORDER BY avg_value DESC;
```

### Product Demographics Analysis Views

```sql
-- View product preferences by age group
SELECT * FROM product_analysis_by_age_group_tableau
WHERE metric_category = 'Product Spending'
ORDER BY age_group_order, product_rank;

-- View spending patterns by family size
SELECT * FROM product_analysis_by_family_size_tableau
WHERE product_name = 'Alcohol'
ORDER BY family_size_order;

-- View product preferences by income bracket
SELECT * FROM product_analysis_by_income_tableau
WHERE metric_category = 'Total Spending'
ORDER BY income_bracket_order;

-- View response rates by customer tenure
SELECT * FROM product_analysis_by_tenure_tableau
WHERE metric_category = 'Customer Engagement'
ORDER BY tenure_group_order;
```

## Key Features

1. **Data Transformation**
   - Date standardization
   - Income normalization
   - Derived metrics calculation
   - Long-format views optimized for Tableau

2. **Demographic Analysis**
   - Age distribution by country
   - Income comparison
   - Family structure analysis
   - Spending patterns across product categories

3. **Marketing Channel Analysis**
   - Channel effectiveness by country
   - Top performing channels ranking
   - Response and complaint analysis
   - Product affinities by channel
   - Revenue attribution by channel
   - Customer behavior patterns by channel

4. **Product Preference Analysis**
   - Product performance by country
   - Age-based product preferences
   - Family size impact on purchases
   - Income-based purchasing patterns
   - Education level correlations
   - Customer loyalty effects
# Chinook Data Analysis

## Overview
This repository demonstrates advanced SQL operations through data analysis tasks using the Chinook database. The project includes data cleaning, feature engineering, partitioning, clustering, and creating insights for reporting platforms like Looker and Power BI.

Google BigQuery is used ofr this project: 
https://console.cloud.google.com/bigquery?ws=!1m7!1m6!12m5!1m3!1schinookproject!2sus-central1!3s5508533d-223d-4c33-980e-ad452f4d7cfa!2e1

The analysis demonstrates real-world scenarios, such as customer churn analysis, sales trends, and dynamic report preparation. 

---

## Project Structure

### 1. **Datasets**
- The project uses the Chinook database, a sample dataset representing a digital media store.
- Tables include: `Customer`, `Invoice`, `InvoiceLine`, `Track`, `Genre`, etc.
[image](https://github.com/user-attachments/assets/a299f80c-bdee-4c1e-9991-ced5444019d0)

### 2. **SQL Queries**
The repository contains two advanced SQL queries that perform the following:

#### **Query 1: Enriched Report for Power BI/Looker**
- Unifies multiple tables into a single dataset.
- Cleans data by removing duplicates.
- Adds new features:
  - `YearMonth` for monthly trends.
  - `TotalCustomerSales`, `TotalCustomerOrders`, and `AverageOrderValue` for customer analysis.
  - `ChurnFlag` to identify churned customers (no purchases in the last 6 months).
- Uses **partitioning** by `InvoiceDate` and **clustering** by `CustomerId` for optimized performance.

#### **Query 2: Feature Engineering with Invoice Table**
- Adds a new column, `InvoiceYearMonth`, representing the year and month of each invoice.
- Updates the `Invoice` table to convert the `InvoiceDate` column from `TIMESTAMP` to `DATE`.
- Prepares the data for time-series analysis and monthly aggregation.

---

## Key Features

### Data Cleaning
- Duplicate removal using `ROW_NUMBER()` and filtering.
- Handling of null and inconsistent data.

### Feature Engineering
- Temporal features: `YearMonth` and `InvoiceYearMonth`.
- Sales metrics: `TotalCustomerSales`, `TotalCustomerOrders`, and `AverageOrderValue`.
- Customer segmentation: `ChurnFlag`.

### Partitioning and Clustering
- Partitioning by `InvoiceDate` for optimized date range queries.
- Clustering by `CustomerId` for faster customer-level analysis.

### Reporting Preparation
- Unified dataset for seamless integration with Power BI or Looker.
- Metrics and features designed to create dynamic dashboards, such as:
  - **Sales Trends**
  - **Churn Analysis**
  - **Customer Insights**

---
## How to Use

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your_username/chinook_data_analysis.git
   cd chinook_data_analysis

### Looker Report
- Chinook_Report table transvered to LOOKER from BigQuery to prepation of visual reports for further analysis.
  ![image](https://github.com/user-attachments/assets/ec0fbf4d-7a0f-4f32-b152-058486eab50f)
  ![image](https://github.com/user-attachments/assets/a37140f5-c2df-4bf3-943a-721f7f9b2ad5)
  ![image](https://github.com/user-attachments/assets/2ce19572-300e-4fde-b257-6590c45fc27e)



  

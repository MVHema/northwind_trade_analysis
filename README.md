# Northwind International Trade Analysis

## Project Overview
SQL analysis of the classic Northwind database - a real-world dataset 
used in SQL training worldwide. Analysis covers customer behaviour, 
revenue trends, product performance and employee efficiency across 
21 countries and 3 years of trading data.

## Tools Used
- SQL (PostgreSQL 15)
- DB Fiddle.com

## Database Structure
14 tables covering the full order lifecycle of an international food 
and beverage trading company.

| Key Table | Description |
|---|---|
| customers | 91 customers across 21 countries |
| orders | 830 orders from 1996 to 1998 |
| order_details | Line items with price, quantity and discount |
| products | 77 products across 8 categories |
| employees | 9 sales employees |
| categories | 8 product categories |
| suppliers | 29 suppliers across 16 countries |

## Business Questions Answered

### Customer Analysis
- Customer distribution across 21 countries
- Customers who have never placed an order
- Top 10 customers by total order value
- Average orders per customer
- Customers active in 1997 but not 1998

### Revenue Analysis
- Annual revenue comparison 1996-1998
- Monthly revenue trend with running total
- Month over month growth rate for 1997
- Revenue breakdown by country
- Peak revenue month identification

### Product Analysis
- Top 10 revenue generating products
- Products that have never been ordered
- Best selling product in each category
- Most frequently bought together product pairs
- Category revenue share percentage

### Employee Analysis
- Employee with most orders handled
- Revenue and average order value per employee
- Employees performing above average

### Advanced Analysis
- Customer first order, last order and days active
- Top 3 spending customers per country

## Key Findings
- **Top Country:** USA generates highest total revenue
- **Top Employee:** Margaret Peacock handles most orders
- **Never Ordered:** Several products show zero sales
- **Peak Month:** Strong seasonal patterns visible in 1997 data
- **Customer Loyalty:** Significant gap between top and average customer spending

## SQL Concepts Used
- Multi-table JOINs across 4+ tables
- Common Table Expressions (CTEs)
- Window Functions (RANK, DENSE_RANK, LAG, SUM OVER)
- Window Frames (ROWS BETWEEN)
- Self JOIN for product pair analysis
- EXISTS / NOT EXISTS filtering
- Set Operations (EXCEPT)
- EXTRACT for PostgreSQL date functions
- Correlated subqueries
- CASE WHEN for performance tagging

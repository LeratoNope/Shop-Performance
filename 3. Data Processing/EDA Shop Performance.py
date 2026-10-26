# Databricks notebook source
# MAGIC %md
# MAGIC 0. Import Libraries

# COMMAND ----------

import pandas as pd
import numpy as np

# COMMAND ----------

# MAGIC %md
# MAGIC #Customers Table
# MAGIC
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC 1. Data Ingestion and converting table into a panda dataframe
# MAGIC

# COMMAND ----------

# DBTITLE 1,Cell 4
customer=spark.table("shop_performance.default.customers")
customer=customer.toPandas()
display(customer)

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Inspect the Customer Table
# MAGIC

# COMMAND ----------

##Check total number of rows and columns
customer.shape

# COMMAND ----------

# DBTITLE 1,Cell 6
# See column types and any missing values
## Signup date is object and not datetime
### From the result, total # of rows is 10000, but age 9820 and city 9881. This means there are missing vlaues in the 2 columns
customer.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Checking for missing values. 
# MAGIC 3a. Replace the missing age with the average age(mean).
# MAGIC 3b. Replace missing city names with "unknown".
# MAGIC
# MAGIC

# COMMAND ----------

# DBTITLE 1,Cell 9
##Identify columns with missing values and the total number of missing values in that column
customer.isnull().sum()

##Look at the smallest and largest numbers in each numeric column
customer["Age"].describe()

##Replace missing age with the avarage
customer["Age"] = customer["Age"].fillna(customer["Age"].median().round(0))

##Replace missing city with "unknown"
customer["City"] = customer["City"].fillna("Unknown")

##To check that the missing values have been replaced
display(customer[["Age", "City"]])

display(customer[["Age", "City"]].isnull().sum())

# COMMAND ----------

##Convert SignupDate from obect to datetime
customer["SignupDate"] = pd.to_datetime(customer["SignupDate"], errors="coerce")

##Check if the datatype has changed
customer.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Check for duplicates

# COMMAND ----------

#Count the number of duplicate
customer.duplicated().sum()

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Unique value counts to check

# COMMAND ----------

##Check the cities before cleaning
display(customer["City"].value_counts(dropna=False))

##str.strip() removes spaces at the start and end
##str.title() makes the first letter of each word a capital and the rest lowercase,
##so "tehran" and "Tehran" both become "Tehran"
customer["City"] = customer["City"].str.strip().str.title()

##Fix the spelling variant (Mashad becomes Mashhad) and change the text "None" to "Unknown"
customer["City"] = customer["City"].replace({"None": "Unknown", "Mashad": "Mashhad"})

##Replace blank cities with "Unknown"
customer["City"] = customer["City"].fillna("Unknown")

##Final check: each city should appear once, with no blanks
display(customer["City"].value_counts(dropna=False))
customer.info()

# COMMAND ----------

# MAGIC %md
# MAGIC # Orders Table
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC 1. Data Ingestion and converting table into a panda dataframe

# COMMAND ----------

# MAGIC %md
# MAGIC

# COMMAND ----------

# DBTITLE 1,Cell 18
orders=spark.table("shop_performance.default.orders")
orders=orders.toPandas()
display(orders)

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Inspect the Orders Table

# COMMAND ----------

## Check total number of rows and columns
orders.shape

# COMMAND ----------

# Check column types and missing values
## Orderdate data type is an object and should be converted to datetime
### From the results,total number of rows is 50120, but OrderDate 50085, Quantity 50040, Discount 49899, PaymentMethod 49668 
orders.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Check for missing values and replace them accordingly

# COMMAND ----------

##Remove rows where Quantity is 0 or negative (NaN rows are kept for now)
orders = orders[~(orders["Quantity"] <= 0)]

##Replace missing quantity with the most common quantity (the mode)
quantity_mode = orders["Quantity"].mode()[0]
orders["Quantity"] = orders["Quantity"].fillna(quantity_mode)

##Quantity should be a whole number
orders["Quantity"] = orders["Quantity"].astype(int)

##80 Missing quantity values set to 1, the most common quantity

##Checks
display(orders["Quantity"].isnull().sum())
display(orders["Quantity"].value_counts().sort_index())   # should now start at 1 and end at 5
display(orders["Quantity"].dtype)

# COMMAND ----------

#Convert the OrderDate from object to datetime
orders["OrderDate"] = pd.to_datetime(orders["OrderDate"], errors="coerce")

##Check if the datatype has changed
orders.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Check for duplicates
# MAGIC

# COMMAND ----------

#Count the number of duplicates
##120 Duplicates were found
orders.duplicated().sum()

#Drop the duplicates
orders.drop_duplicates(inplace=True)

#Check if duplicates have been dropped. Output must be 0
orders.duplicated().sum()

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Check unique value counts
# MAGIC

# COMMAND ----------

orders["PaymentMethod"].unique()
orders["Status"].unique()
orders["OrderDate"].unique()

##Final Check
orders.info()

# COMMAND ----------

##Check the smallest and largest discounts (should be between 0 and 1)
display(orders["Discount"].describe())
display(orders["Discount"].value_counts(dropna=False).sort_index())

##Replace missing discount with 0 (no discount recorded, also the most common value)
orders["Discount"] = orders["Discount"].fillna(0)

##Check
display(orders["Discount"].isnull().sum())
display(orders["Discount"].value_counts().sort_index())

# COMMAND ----------

orders["Discount"] = orders["Discount"].fillna(0)
display(orders["Discount"].isnull().sum())

# COMMAND ----------

# DBTITLE 1,Cell 31
display(orders["Status"].value_counts(dropna=False))
display(orders["PaymentMethod"].value_counts(dropna=False))

# COMMAND ----------

##Broken Links
display((~orders["CustomerID"].isin(customer["CustomerID"])).sum())
display((~orders["ProductID"].isin(products["ProductID"])).sum())

##ProductID is clean = 0
##But 30 order lines point to a CustomerID that doesn’t exist in the customers table

##Closer look at the 30 rows:
broken = orders[~orders["CustomerID"].isin(customer["CustomerID"])]
display(broken)
display(broken["CustomerID"].unique())
display(customer["CustomerID"].agg(["min", "max"]))

##Results: 30 order lines used CustomerID 999999, which does not exist in the customers table. This looks like a placeholder for guest or unrecorded customers. The orders are otherwise valid, so they were kept to keep revenue complete

# COMMAND ----------

##Labeling the customers their own name.

##Join to customers (left join keeps all orders)
merged = orders.merge(customer, on="CustomerID", how="left")
display(merged.shape)   # row count must be unchanged

##Label orders placed under the placeholder customer ID
guest = merged["CustomerID"] == 999999
merged.loc[guest, "City"] = "No customer record"
merged.loc[guest, "CustomerSegment"] = "No customer record"

# COMMAND ----------

# MAGIC %md
# MAGIC #  Payments Table
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC 1. Data Ingestion and converting table into a panda dataframe
# MAGIC

# COMMAND ----------

payments=spark.table("shop_performance.default.payments")
payments=payments.toPandas()
display(payments)

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Inspect the Orders Table

# COMMAND ----------

#Check total number of rows and columns
payments.shape

# COMMAND ----------

# From the results,total number of rows is 50000, but paymentdate 49965
## PaymentDate datatype should be converted from object to datetime
payments.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Check for missing values nd replace them accordingly

# COMMAND ----------

payments.isnull().sum()

# COMMAND ----------

#Convert the OrderDate from object to datetime
payments["PaymentDate"] = pd.to_datetime(payments["PaymentDate"], errors="coerce")

##Checking to see the payment status of the 35 dates that are blank. If mostly have failed/pending, then date is missing for a real reason
payments[payments["PaymentDate"].isnull()]

##35 payments with status Paid had no PaymentDate. Rows kept because they are valid payments. Dates left blank; trend analysis uses OrderDate, so revenue reporting is unaffected.

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Checking for duplicates

# COMMAND ----------

payments.duplicated().sum()

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Check unique vlue count

# COMMAND ----------

payments["PaymentStatus"].unique()

##Final Check
payments.info()

# COMMAND ----------

# MAGIC %md
# MAGIC # Product Table
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC 1. Data Ingestion and converting table into a panda dataframe

# COMMAND ----------

products=spark.table("shop_performance.default.products")
products=products.toPandas()
display(products)

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Inspect the Products Table

# COMMAND ----------

#Check for total rows and columns 
products.shape

#See column tpys and missing valus
products.info()

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Check for duplicates

# COMMAND ----------

products["ProductID"].is_unique        # should be True
products["ProductName"].duplicated().sum()   # should be 0

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Check unique value counts

# COMMAND ----------

products["ProductName"].unique()
products["Category"].unique()

# COMMAND ----------

##Price Check
products.sort_values("UnitPrice")[["ProductName", "Category", "UnitPrice"]]
products["UnitPrice"].describe()

# COMMAND ----------

# MAGIC %md
# MAGIC # Merging Tables
# MAGIC

# COMMAND ----------

## Confirm taht ProductID is unique
display(products["ProductID"].is_unique)                           # should be True
display(merged["ProductID"].isin(products["ProductID"]).all())     # should be True

# COMMAND ----------

##Step 0: finish cleaning orders
orders = orders.drop_duplicates().reset_index(drop=True)
orders["Discount"] = orders["Discount"].fillna(0)
display(orders.duplicated().sum())        # expect 0
display(orders.shape)                     # expect about (49975, 8)
display(orders["Discount"].isnull().sum())  # expect 0

##Step 1: checks on payments before joining
display(payments["OrderID"].duplicated().sum())   # expect 0 (one payment per order)
display(payments["PaymentDate"].isnull().sum())   # expect 35 (blanks left as blank)

##Step 2: build the merged table from scratch
merged = orders.merge(customer, on="CustomerID", how="left")
display(merged.shape)        # same rows as orders, 12 columns

guest = merged["CustomerID"] == 999999
merged.loc[guest, "City"] = "No customer record"
merged.loc[guest, "CustomerSegment"] = "No customer record"

merged = merged.merge(products, on="ProductID", how="left")
display(merged.shape)        # same rows, 15 columns

merged = merged.merge(payments, on="OrderID", how="left")
display(merged.shape)        # same rows, 18 columns

display(merged.columns.tolist())   # 18 names, none ending in _x or _y

display(merged["PaymentStatus"].isnull().sum())       # orders with no payment record
display(merged["PaymentStatus"].value_counts(dropna=False))

# COMMAND ----------

## Confirming the final shape
display(merged.shape)

# COMMAND ----------

# MAGIC %md
# MAGIC # Creating the new columns

# COMMAND ----------

##Revenue for each order line (before deciding what counts)
merged["Revenue"] = merged["Quantity"] * merged["UnitPrice"] * (1 - merged["Discount"])

##Year and Month from OrderDate (blank dates stay blank)
merged["Year"] = merged["OrderDate"].dt.year
merged["Month"] = merged["OrderDate"].dt.month

##Checks
display(merged[["OrderDate", "Quantity", "UnitPrice", "Discount", "Revenue", "Year", "Month"]].head(10))
display(merged["Revenue"].describe())
display(merged["Revenue"].isnull().sum())   # expect 0
display(merged["Year"].isnull().sum())      # expect about 35 (the blank OrderDates)

# COMMAND ----------

## Only Completed and Paid orders count as revenue, because cancelled, returned, failed or refunded orders did not bring in money

##Round revenue to 2 decimals
merged["Revenue"] = merged["Revenue"].round(2)

##Revenue only counts orders that were Completed and Paid
valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]

# COMMAND ----------

# MAGIC %md
# MAGIC # Answering the business questions

# COMMAND ----------

##Question 1: Total revenue, orders and average order value

##Revenue only counts orders that were Completed and Paid
valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]

##Headline numbers
total_revenue = valid_sales["Revenue"].sum()
total_orders = valid_sales["OrderID"].nunique()
avg_order_value = total_revenue / total_orders

print("Total revenue:", round(total_revenue, 2))
print("Number of orders:", total_orders)
print("Average order value:", round(avg_order_value, 2))

# COMMAND ----------

##Question 2: Is revenue growing, shrinking or flat? Any seasonal peaks?

##Year-month column for the trend (blank dates become "NaT")
merged["YearMonth"] = merged["OrderDate"].dt.to_period("M").astype(str)

##Re-create valid_sales so it includes YearMonth
valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]

##Revenue per month (leave out the orders with no date)
monthly = valid_sales.groupby("YearMonth")["Revenue"].sum().round(2).reset_index()
monthly = monthly[monthly["YearMonth"] != "NaT"]
display(monthly)

##Line chart
monthly.plot(x="YearMonth", y="Revenue", kind="line", figsize=(12, 5), title="Monthly revenue")

# COMMAND ----------

## Explaining the drop in sales
## What caused the drop? Compare orders, order value and the share of valid orders by month
m = merged[merged["YearMonth"] != "NaT"]
v = valid_sales[valid_sales["YearMonth"] != "NaT"]

orders_per_month = v.groupby("YearMonth")["OrderID"].nunique()
avg_order_value = (v.groupby("YearMonth")["Revenue"].sum() / orders_per_month).round(2)
share_valid = (orders_per_month / m.groupby("YearMonth")["OrderID"].nunique()).round(3)

display(pd.DataFrame({"orders": orders_per_month,
                      "avg_order_value": avg_order_value,
                      "share_valid": share_valid}).tail(12))

##The drop in revenue is caused by fewer orders, meaning that the order value fell.

# COMMAND ----------

# MAGIC %md
# MAGIC

# COMMAND ----------

##Question 3: Which products and categories bring in the most revenue? Which sell the most units? Are they the same?

##Revenue by product (highest first)
product_revenue = valid_sales.groupby("ProductName")["Revenue"].sum().sort_values(ascending=False)
display(product_revenue.round(2))

##Units sold by product (highest first)
product_units = valid_sales.groupby("ProductName")["Quantity"].sum().sort_values(ascending=False)
display(product_units)

##Revenue by category
category_revenue = valid_sales.groupby("Category")["Revenue"].sum().sort_values(ascending=False)
display(category_revenue.round(2))

##Units sold by category
category_units = valid_sales.groupby("Category")["Quantity"].sum().sort_values(ascending=False)
display(category_units)

# COMMAND ----------

##Question 4: Cities and customer segments

##Revenue by city (highest first)
city_revenue = valid_sales.groupby("City")["Revenue"].sum().sort_values(ascending=False)
display(city_revenue.round(2))

##Number of orders by city
city_orders = valid_sales.groupby("City")["OrderID"].nunique().sort_values(ascending=False)
display(city_orders)

##Revenue by customer segment (highest first)
segment_revenue = valid_sales.groupby("CustomerSegment")["Revenue"].sum().sort_values(ascending=False)
display(segment_revenue.round(2))

##Number of orders by customer segment
segment_orders = valid_sales.groupby("CustomerSegment")["OrderID"].nunique().sort_values(ascending=False)
display(segment_orders)

##Tehran brings in over a quarter of revenue and drives the shop mainly through order volume. Regular customers bring in over half of revenue, and VIP customers, the smallest group, don’t spend more per order than others.

# COMMAND ----------

##Question 5: Cancelled, returned and failed

##Check that each order is one row (should be True)
display(merged["OrderID"].is_unique)

##Order status: counts and percentages
status_counts = merged["Status"].value_counts()
display(status_counts)
display((status_counts / len(merged) * 100).round(1))

##Payment status: counts and percentages
payment_counts = merged["PaymentStatus"].value_counts()
display(payment_counts)
display((payment_counts / len(merged) * 100).round(1))

##Failed payments by payment method
failed = merged[merged["PaymentStatus"] == "Failed"]
failed_by_method = failed.groupby("PaymentMethod")["OrderID"].count()
all_by_method = merged.groupby("PaymentMethod")["OrderID"].count()
failure_rate = (failed_by_method / all_by_method * 100).round(1).sort_values(ascending=False)
display(failure_rate)

##about 1 in 12 orders is cancelled or returned and about 1 in 26 payments fails, and since every payment method fails at nearly the same rate, the problem isn’t one particular method.

##The two status columns don’t match perfectly. 45,972 orders are marked Completed, but only 42,825 are both Completed and Paid, which is what you count as revenue. So about 3,150 Completed orders had a Failed or Refunded payment, and they’re excluded from revenue.

# COMMAND ----------

##Question 6: Do bigger discounts lead to bigger orders, or just lower revenue?

##Number of orders at each discount level
display(valid_sales.groupby("Discount")["OrderID"].nunique())

##Average quantity per order at each discount level
display(valid_sales.groupby("Discount")["Quantity"].mean().round(2))

##Average order value at each discount level
display(valid_sales.groupby("Discount")["Revenue"].mean().round(2))

##Total revenue at each discount level
display(valid_sales.groupby("Discount")["Revenue"].sum().round(2))

##No. They just lower revenue per order.

# COMMAND ----------

##Helper columns: 1 if the order counts as revenue, otherwise 0
merged["ValidOrder"] = ((merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")).astype(int)
merged["ValidRevenue"] = merged["Revenue"] * merged["ValidOrder"]

##Pick the columns the dashboard needs
export = merged[["OrderID", "OrderDate", "YearMonth", "Year", "Month", "Status", "PaymentStatus",
                 "PaymentMethod", "City", "CustomerSegment", "ProductName", "Category",
                 "UnitPrice", "Quantity", "Discount", "Revenue", "ValidOrder", "ValidRevenue"]].copy()

##Make the date a plain date (no time)
export["OrderDate"] = export["OrderDate"].dt.strftime("%Y-%m-%d")

display(export.shape)                    # expect (49975, 18)
display(export["ValidRevenue"].sum())    # should be 2994604.45
display(export["ValidOrder"].sum())      # should be 42825
display(export)

# COMMAND ----------

display(export.iloc[0:10000])
display(export.iloc[10000:20000])
display(export.iloc[20000:30000])
display(export.iloc[30000:40000])
display(export.iloc[40000:])
-- Databricks notebook source
-- MAGIC %md
-- MAGIC 0. Import Libraries

-- COMMAND ----------

-- MAGIC %python
-- MAGIC import pandas as pd
-- MAGIC import numpy as np
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #Customers Table
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 1. Data Ingestion and converting table into a panda dataframe
-- MAGIC

-- COMMAND ----------

-- DBTITLE 1,Cell 4
-- MAGIC %python
-- MAGIC customer=spark.table("shop_performance.default.customers")
-- MAGIC customer=customer.toPandas()
-- MAGIC display(customer)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Inspect the Customer Table
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Check total number of rows and columns
-- MAGIC customer.shape
-- MAGIC

-- COMMAND ----------

-- DBTITLE 1,Cell 6
-- MAGIC %python
-- MAGIC # See column types and any missing values
-- MAGIC ## Signup date is object and not datetime
-- MAGIC ### From the result, total # of rows is 10000, but age 9820 and city 9881. This means there are missing vlaues in the 2 columns
-- MAGIC customer.info()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Checking for missing values. 
-- MAGIC 3a. Replace the missing age with the average age(mean).
-- MAGIC 3b. Replace missing city names with "unknown".
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- DBTITLE 1,Cell 9
-- MAGIC %python
-- MAGIC ##Identify columns with missing values and the total number of missing values in that column
-- MAGIC customer.isnull().sum()
-- MAGIC
-- MAGIC ##Look at the smallest and largest numbers in each numeric column
-- MAGIC customer["Age"].describe()
-- MAGIC
-- MAGIC ##Replace missing age with the avarage
-- MAGIC customer["Age"] = customer["Age"].fillna(customer["Age"].median().round(0))
-- MAGIC
-- MAGIC ##Replace missing city with "unknown"
-- MAGIC customer["City"] = customer["City"].fillna("Unknown")
-- MAGIC
-- MAGIC ##To check that the missing values have been replaced
-- MAGIC display(customer[["Age", "City"]])
-- MAGIC
-- MAGIC display(customer[["Age", "City"]].isnull().sum())

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Convert SignupDate from obect to datetime
-- MAGIC customer["SignupDate"] = pd.to_datetime(customer["SignupDate"], errors="coerce")
-- MAGIC
-- MAGIC ##Check if the datatype has changed
-- MAGIC customer.info()
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Check for duplicates

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Count the number of duplicate
-- MAGIC customer.duplicated().sum()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Unique value counts to check

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Check the cities before cleaning
-- MAGIC display(customer["City"].value_counts(dropna=False))
-- MAGIC
-- MAGIC ##str.strip() removes spaces at the start and end
-- MAGIC ##str.title() makes the first letter of each word a capital and the rest lowercase,
-- MAGIC ##so "tehran" and "Tehran" both become "Tehran"
-- MAGIC customer["City"] = customer["City"].str.strip().str.title()
-- MAGIC
-- MAGIC ##Fix the spelling variant (Mashad becomes Mashhad) and change the text "None" to "Unknown"
-- MAGIC customer["City"] = customer["City"].replace({"None": "Unknown", "Mashad": "Mashhad"})
-- MAGIC
-- MAGIC ##Replace blank cities with "Unknown"
-- MAGIC customer["City"] = customer["City"].fillna("Unknown")
-- MAGIC
-- MAGIC ##Final check: each city should appear once, with no blanks
-- MAGIC display(customer["City"].value_counts(dropna=False))
-- MAGIC customer.info()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Orders Table
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 1. Data Ingestion and converting table into a panda dataframe

-- COMMAND ----------

-- MAGIC %md
-- MAGIC

-- COMMAND ----------

-- DBTITLE 1,Cell 18
-- MAGIC %python
-- MAGIC orders=spark.table("shop_performance.default.orders")
-- MAGIC orders=orders.toPandas()
-- MAGIC display(orders)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Inspect the Orders Table

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ## Check total number of rows and columns
-- MAGIC orders.shape

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Check column types and missing values
-- MAGIC ## Orderdate data type is an object and should be converted to datetime
-- MAGIC ### From the results,total number of rows is 50120, but OrderDate 50085, Quantity 50040, Discount 49899, PaymentMethod 49668 
-- MAGIC orders.info()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Check for missing values and replace them accordingly

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Remove rows where Quantity is 0 or negative (NaN rows are kept for now)
-- MAGIC orders = orders[~(orders["Quantity"] <= 0)]
-- MAGIC
-- MAGIC ##Replace missing quantity with the most common quantity (the mode)
-- MAGIC quantity_mode = orders["Quantity"].mode()[0]
-- MAGIC orders["Quantity"] = orders["Quantity"].fillna(quantity_mode)
-- MAGIC
-- MAGIC ##Quantity should be a whole number
-- MAGIC orders["Quantity"] = orders["Quantity"].astype(int)
-- MAGIC
-- MAGIC ##80 Missing quantity values set to 1, the most common quantity
-- MAGIC
-- MAGIC ##Checks
-- MAGIC display(orders["Quantity"].isnull().sum())
-- MAGIC display(orders["Quantity"].value_counts().sort_index())   # should now start at 1 and end at 5
-- MAGIC display(orders["Quantity"].dtype)
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Convert the OrderDate from object to datetime
-- MAGIC orders["OrderDate"] = pd.to_datetime(orders["OrderDate"], errors="coerce")
-- MAGIC
-- MAGIC ##Check if the datatype has changed
-- MAGIC orders.info()
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Check for duplicates
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Count the number of duplicates
-- MAGIC ##120 Duplicates were found
-- MAGIC orders.duplicated().sum()
-- MAGIC
-- MAGIC #Drop the duplicates
-- MAGIC orders.drop_duplicates(inplace=True)
-- MAGIC
-- MAGIC #Check if duplicates have been dropped. Output must be 0
-- MAGIC orders.duplicated().sum()
-- MAGIC
-- MAGIC
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Check unique value counts
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC orders["PaymentMethod"].unique()
-- MAGIC orders["Status"].unique()
-- MAGIC orders["OrderDate"].unique()
-- MAGIC
-- MAGIC ##Final Check
-- MAGIC orders.info()
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Check the smallest and largest discounts (should be between 0 and 1)
-- MAGIC display(orders["Discount"].describe())
-- MAGIC display(orders["Discount"].value_counts(dropna=False).sort_index())
-- MAGIC
-- MAGIC ##Replace missing discount with 0 (no discount recorded, also the most common value)
-- MAGIC orders["Discount"] = orders["Discount"].fillna(0)
-- MAGIC
-- MAGIC ##Check
-- MAGIC display(orders["Discount"].isnull().sum())
-- MAGIC display(orders["Discount"].value_counts().sort_index())

-- COMMAND ----------

-- MAGIC %python
-- MAGIC orders["Discount"] = orders["Discount"].fillna(0)
-- MAGIC display(orders["Discount"].isnull().sum())

-- COMMAND ----------

-- DBTITLE 1,Cell 31
-- MAGIC %python
-- MAGIC display(orders["Status"].value_counts(dropna=False))
-- MAGIC display(orders["PaymentMethod"].value_counts(dropna=False))

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Broken Links
-- MAGIC display((~orders["CustomerID"].isin(customer["CustomerID"])).sum())
-- MAGIC display((~orders["ProductID"].isin(products["ProductID"])).sum())
-- MAGIC
-- MAGIC ##ProductID is clean = 0
-- MAGIC ##But 30 order lines point to a CustomerID that doesn’t exist in the customers table
-- MAGIC
-- MAGIC ##Closer look at the 30 rows:
-- MAGIC broken = orders[~orders["CustomerID"].isin(customer["CustomerID"])]
-- MAGIC display(broken)
-- MAGIC display(broken["CustomerID"].unique())
-- MAGIC display(customer["CustomerID"].agg(["min", "max"]))
-- MAGIC
-- MAGIC ##Results: 30 order lines used CustomerID 999999, which does not exist in the customers table. This looks like a placeholder for guest or unrecorded customers. The orders are otherwise valid, so they were kept to keep revenue complete

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Labeling the customers their own name.
-- MAGIC
-- MAGIC ##Join to customers (left join keeps all orders)
-- MAGIC merged = orders.merge(customer, on="CustomerID", how="left")
-- MAGIC display(merged.shape)   # row count must be unchanged
-- MAGIC
-- MAGIC ##Label orders placed under the placeholder customer ID
-- MAGIC guest = merged["CustomerID"] == 999999
-- MAGIC merged.loc[guest, "City"] = "No customer record"
-- MAGIC merged.loc[guest, "CustomerSegment"] = "No customer record"

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #  Payments Table
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 1. Data Ingestion and converting table into a panda dataframe
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC payments=spark.table("shop_performance.default.payments")
-- MAGIC payments=payments.toPandas()
-- MAGIC display(payments)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Inspect the Orders Table

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Check total number of rows and columns
-- MAGIC payments.shape

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # From the results,total number of rows is 50000, but paymentdate 49965
-- MAGIC ## PaymentDate datatype should be converted from object to datetime
-- MAGIC payments.info()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Check for missing values nd replace them accordingly

-- COMMAND ----------

-- MAGIC %python
-- MAGIC payments.isnull().sum()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Convert the OrderDate from object to datetime
-- MAGIC payments["PaymentDate"] = pd.to_datetime(payments["PaymentDate"], errors="coerce")
-- MAGIC
-- MAGIC ##Checking to see the payment status of the 35 dates that are blank. If mostly have failed/pending, then date is missing for a real reason
-- MAGIC payments[payments["PaymentDate"].isnull()]
-- MAGIC
-- MAGIC ##35 payments with status Paid had no PaymentDate. Rows kept because they are valid payments. Dates left blank; trend analysis uses OrderDate, so revenue reporting is unaffected.
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Checking for duplicates

-- COMMAND ----------

-- MAGIC %python
-- MAGIC payments.duplicated().sum()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 5. Check unique vlue count

-- COMMAND ----------

-- MAGIC %python
-- MAGIC payments["PaymentStatus"].unique()
-- MAGIC
-- MAGIC ##Final Check
-- MAGIC payments.info()
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Product Table
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 1. Data Ingestion and converting table into a panda dataframe

-- COMMAND ----------

-- MAGIC %python
-- MAGIC products=spark.table("shop_performance.default.products")
-- MAGIC products=products.toPandas()
-- MAGIC display(products)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 2. Inspect the Products Table

-- COMMAND ----------

-- MAGIC %python
-- MAGIC #Check for total rows and columns 
-- MAGIC products.shape
-- MAGIC
-- MAGIC #See column tpys and missing valus
-- MAGIC products.info()
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 3. Check for duplicates

-- COMMAND ----------

-- MAGIC %python
-- MAGIC products["ProductID"].is_unique        # should be True
-- MAGIC products["ProductName"].duplicated().sum()   # should be 0

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 4. Check unique value counts

-- COMMAND ----------

-- MAGIC %python
-- MAGIC products["ProductName"].unique()
-- MAGIC products["Category"].unique()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Price Check
-- MAGIC products.sort_values("UnitPrice")[["ProductName", "Category", "UnitPrice"]]
-- MAGIC products["UnitPrice"].describe()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Merging Tables
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ## Confirm taht ProductID is unique
-- MAGIC display(products["ProductID"].is_unique)                           # should be True
-- MAGIC display(merged["ProductID"].isin(products["ProductID"]).all())     # should be True

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Step 0: finish cleaning orders
-- MAGIC orders = orders.drop_duplicates().reset_index(drop=True)
-- MAGIC orders["Discount"] = orders["Discount"].fillna(0)
-- MAGIC display(orders.duplicated().sum())        # expect 0
-- MAGIC display(orders.shape)                     # expect about (49975, 8)
-- MAGIC display(orders["Discount"].isnull().sum())  # expect 0
-- MAGIC
-- MAGIC ##Step 1: checks on payments before joining
-- MAGIC display(payments["OrderID"].duplicated().sum())   # expect 0 (one payment per order)
-- MAGIC display(payments["PaymentDate"].isnull().sum())   # expect 35 (blanks left as blank)
-- MAGIC
-- MAGIC ##Step 2: build the merged table from scratch
-- MAGIC merged = orders.merge(customer, on="CustomerID", how="left")
-- MAGIC display(merged.shape)        # same rows as orders, 12 columns
-- MAGIC
-- MAGIC guest = merged["CustomerID"] == 999999
-- MAGIC merged.loc[guest, "City"] = "No customer record"
-- MAGIC merged.loc[guest, "CustomerSegment"] = "No customer record"
-- MAGIC
-- MAGIC merged = merged.merge(products, on="ProductID", how="left")
-- MAGIC display(merged.shape)        # same rows, 15 columns
-- MAGIC
-- MAGIC merged = merged.merge(payments, on="OrderID", how="left")
-- MAGIC display(merged.shape)        # same rows, 18 columns
-- MAGIC
-- MAGIC display(merged.columns.tolist())   # 18 names, none ending in _x or _y
-- MAGIC
-- MAGIC display(merged["PaymentStatus"].isnull().sum())       # orders with no payment record
-- MAGIC display(merged["PaymentStatus"].value_counts(dropna=False))

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ## Confirming the final shape
-- MAGIC display(merged.shape) 

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Creating the new columns

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Revenue for each order line (before deciding what counts)
-- MAGIC merged["Revenue"] = merged["Quantity"] * merged["UnitPrice"] * (1 - merged["Discount"])
-- MAGIC
-- MAGIC ##Year and Month from OrderDate (blank dates stay blank)
-- MAGIC merged["Year"] = merged["OrderDate"].dt.year
-- MAGIC merged["Month"] = merged["OrderDate"].dt.month
-- MAGIC
-- MAGIC ##Checks
-- MAGIC display(merged[["OrderDate", "Quantity", "UnitPrice", "Discount", "Revenue", "Year", "Month"]].head(10))
-- MAGIC display(merged["Revenue"].describe())
-- MAGIC display(merged["Revenue"].isnull().sum())   # expect 0
-- MAGIC display(merged["Year"].isnull().sum())      # expect about 35 (the blank OrderDates)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ## Only Completed and Paid orders count as revenue, because cancelled, returned, failed or refunded orders did not bring in money
-- MAGIC
-- MAGIC ##Round revenue to 2 decimals
-- MAGIC merged["Revenue"] = merged["Revenue"].round(2)
-- MAGIC
-- MAGIC ##Revenue only counts orders that were Completed and Paid
-- MAGIC valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]
-- MAGIC
-- MAGIC
-- MAGIC

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Answering the business questions

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 1: Total revenue, orders and average order value
-- MAGIC
-- MAGIC ##Revenue only counts orders that were Completed and Paid
-- MAGIC valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]
-- MAGIC
-- MAGIC ##Headline numbers
-- MAGIC total_revenue = valid_sales["Revenue"].sum()
-- MAGIC total_orders = valid_sales["OrderID"].nunique()
-- MAGIC avg_order_value = total_revenue / total_orders
-- MAGIC
-- MAGIC print("Total revenue:", round(total_revenue, 2))
-- MAGIC print("Number of orders:", total_orders)
-- MAGIC print("Average order value:", round(avg_order_value, 2))

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 2: Is revenue growing, shrinking or flat? Any seasonal peaks?
-- MAGIC
-- MAGIC ##Year-month column for the trend (blank dates become "NaT")
-- MAGIC merged["YearMonth"] = merged["OrderDate"].dt.to_period("M").astype(str)
-- MAGIC
-- MAGIC ##Re-create valid_sales so it includes YearMonth
-- MAGIC valid_sales = merged[(merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")]
-- MAGIC
-- MAGIC ##Revenue per month (leave out the orders with no date)
-- MAGIC monthly = valid_sales.groupby("YearMonth")["Revenue"].sum().round(2).reset_index()
-- MAGIC monthly = monthly[monthly["YearMonth"] != "NaT"]
-- MAGIC display(monthly)
-- MAGIC
-- MAGIC ##Line chart
-- MAGIC monthly.plot(x="YearMonth", y="Revenue", kind="line", figsize=(12, 5), title="Monthly revenue")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ## Explaining the drop in sales
-- MAGIC ## What caused the drop? Compare orders, order value and the share of valid orders by month
-- MAGIC m = merged[merged["YearMonth"] != "NaT"]
-- MAGIC v = valid_sales[valid_sales["YearMonth"] != "NaT"]
-- MAGIC
-- MAGIC orders_per_month = v.groupby("YearMonth")["OrderID"].nunique()
-- MAGIC avg_order_value = (v.groupby("YearMonth")["Revenue"].sum() / orders_per_month).round(2)
-- MAGIC share_valid = (orders_per_month / m.groupby("YearMonth")["OrderID"].nunique()).round(3)
-- MAGIC
-- MAGIC display(pd.DataFrame({"orders": orders_per_month,
-- MAGIC                       "avg_order_value": avg_order_value,
-- MAGIC                       "share_valid": share_valid}).tail(12))
-- MAGIC
-- MAGIC ##The drop in revenue is caused by fewer orders, meaning that the order value fell.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 3: Which products and categories bring in the most revenue? Which sell the most units? Are they the same?
-- MAGIC
-- MAGIC ##Revenue by product (highest first)
-- MAGIC product_revenue = valid_sales.groupby("ProductName")["Revenue"].sum().sort_values(ascending=False)
-- MAGIC display(product_revenue.round(2))
-- MAGIC
-- MAGIC ##Units sold by product (highest first)
-- MAGIC product_units = valid_sales.groupby("ProductName")["Quantity"].sum().sort_values(ascending=False)
-- MAGIC display(product_units)
-- MAGIC
-- MAGIC ##Revenue by category
-- MAGIC category_revenue = valid_sales.groupby("Category")["Revenue"].sum().sort_values(ascending=False)
-- MAGIC display(category_revenue.round(2))
-- MAGIC
-- MAGIC ##Units sold by category
-- MAGIC category_units = valid_sales.groupby("Category")["Quantity"].sum().sort_values(ascending=False)
-- MAGIC display(category_units)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 4: Cities and customer segments
-- MAGIC
-- MAGIC ##Revenue by city (highest first)
-- MAGIC city_revenue = valid_sales.groupby("City")["Revenue"].sum().sort_values(ascending=False)
-- MAGIC display(city_revenue.round(2))
-- MAGIC
-- MAGIC ##Number of orders by city
-- MAGIC city_orders = valid_sales.groupby("City")["OrderID"].nunique().sort_values(ascending=False)
-- MAGIC display(city_orders)
-- MAGIC
-- MAGIC ##Revenue by customer segment (highest first)
-- MAGIC segment_revenue = valid_sales.groupby("CustomerSegment")["Revenue"].sum().sort_values(ascending=False)
-- MAGIC display(segment_revenue.round(2))
-- MAGIC
-- MAGIC ##Number of orders by customer segment
-- MAGIC segment_orders = valid_sales.groupby("CustomerSegment")["OrderID"].nunique().sort_values(ascending=False)
-- MAGIC display(segment_orders)
-- MAGIC
-- MAGIC ##Tehran brings in over a quarter of revenue and drives the shop mainly through order volume. Regular customers bring in over half of revenue, and VIP customers, the smallest group, don’t spend more per order than others.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 5: Cancelled, returned and failed
-- MAGIC
-- MAGIC ##Check that each order is one row (should be True)
-- MAGIC display(merged["OrderID"].is_unique)
-- MAGIC
-- MAGIC ##Order status: counts and percentages
-- MAGIC status_counts = merged["Status"].value_counts()
-- MAGIC display(status_counts)
-- MAGIC display((status_counts / len(merged) * 100).round(1))
-- MAGIC
-- MAGIC ##Payment status: counts and percentages
-- MAGIC payment_counts = merged["PaymentStatus"].value_counts()
-- MAGIC display(payment_counts)
-- MAGIC display((payment_counts / len(merged) * 100).round(1))
-- MAGIC
-- MAGIC ##Failed payments by payment method
-- MAGIC failed = merged[merged["PaymentStatus"] == "Failed"]
-- MAGIC failed_by_method = failed.groupby("PaymentMethod")["OrderID"].count()
-- MAGIC all_by_method = merged.groupby("PaymentMethod")["OrderID"].count()
-- MAGIC failure_rate = (failed_by_method / all_by_method * 100).round(1).sort_values(ascending=False)
-- MAGIC display(failure_rate)
-- MAGIC
-- MAGIC ##about 1 in 12 orders is cancelled or returned and about 1 in 26 payments fails, and since every payment method fails at nearly the same rate, the problem isn’t one particular method.
-- MAGIC
-- MAGIC ##The two status columns don’t match perfectly. 45,972 orders are marked Completed, but only 42,825 are both Completed and Paid, which is what you count as revenue. So about 3,150 Completed orders had a Failed or Refunded payment, and they’re excluded from revenue.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Question 6: Do bigger discounts lead to bigger orders, or just lower revenue?
-- MAGIC
-- MAGIC ##Number of orders at each discount level
-- MAGIC display(valid_sales.groupby("Discount")["OrderID"].nunique())
-- MAGIC
-- MAGIC ##Average quantity per order at each discount level
-- MAGIC display(valid_sales.groupby("Discount")["Quantity"].mean().round(2))
-- MAGIC
-- MAGIC ##Average order value at each discount level
-- MAGIC display(valid_sales.groupby("Discount")["Revenue"].mean().round(2))
-- MAGIC
-- MAGIC ##Total revenue at each discount level
-- MAGIC display(valid_sales.groupby("Discount")["Revenue"].sum().round(2))
-- MAGIC
-- MAGIC ##No. They just lower revenue per order.
-- MAGIC

-- COMMAND ----------

-- MAGIC %python
-- MAGIC ##Helper columns: 1 if the order counts as revenue, otherwise 0
-- MAGIC merged["ValidOrder"] = ((merged["Status"] == "Completed") & (merged["PaymentStatus"] == "Paid")).astype(int)
-- MAGIC merged["ValidRevenue"] = merged["Revenue"] * merged["ValidOrder"]
-- MAGIC
-- MAGIC ##Pick the columns the dashboard needs
-- MAGIC export = merged[["OrderID", "OrderDate", "YearMonth", "Year", "Month", "Status", "PaymentStatus",
-- MAGIC                  "PaymentMethod", "City", "CustomerSegment", "ProductName", "Category",
-- MAGIC                  "UnitPrice", "Quantity", "Discount", "Revenue", "ValidOrder", "ValidRevenue"]].copy()
-- MAGIC
-- MAGIC ##Make the date a plain date (no time)
-- MAGIC export["OrderDate"] = export["OrderDate"].dt.strftime("%Y-%m-%d")
-- MAGIC
-- MAGIC display(export.shape)                    # expect (49975, 18)
-- MAGIC display(export["ValidRevenue"].sum())    # should be 2994604.45
-- MAGIC display(export["ValidOrder"].sum())      # should be 42825
-- MAGIC display(export)

-- COMMAND ----------

-- MAGIC %python
-- MAGIC display(export.iloc[0:10000])
-- MAGIC display(export.iloc[10000:20000])
-- MAGIC display(export.iloc[20000:30000])
-- MAGIC display(export.iloc[30000:40000])
-- MAGIC display(export.iloc[40000:])
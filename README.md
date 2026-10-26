# Shop-Performance
# 🛍️ How Is the Shop Performing? Sales Analysis Case Study

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![pandas](https://img.shields.io/badge/pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=for-the-badge&logo=databricks&logoColor=white)
![Looker Studio](https://img.shields.io/badge/Looker_Studio-4285F4?style=for-the-badge)

A beginner data analysis case study from the **BrightLearn Data Analytics Program**. Four raw data files from an online shop are cleaned, combined and turned into a clear picture of how the business performed between **January 2024 and June 2026**, written for a Head of Operations who is not a data person.

---

## 📌 Project Overview

You have just joined an online shop that sells electronics, accessories, wearables, home office items, stationery and gaming products. The Head of Operations wants simple numbers, clear charts and plain-language explanations. The deliverable is a short dashboard that answers the business questions below and ends with **three recommendations** they can act on.

**Live dashboard:** [add your Looker Studio link here]

---

## 🎯 Business Questions

1. How much revenue did the shop make, from how many orders, and what is the average order value?
2. Is revenue growing, shrinking or flat month by month? Are there seasonal peaks?
3. Which products and categories bring in the most revenue, and which sell the most units?
4. Which cities and customer segments (New, Regular, VIP) are the most valuable?
5. What share of orders are cancelled or returned, and what share of payments fail?
6. Do bigger discounts lead to bigger orders, or just lower revenue?

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **Databricks** | Hosting the data tables and running the notebook |
| **Python (pandas)** | Cleaning, joining, creating new columns and answering the business questions |
| **Looker Studio** | Building the 6-page dashboard |

---

## 📂 The Data

| File | What it contains | Rows |
|---|---|---|
| `customers.csv` | One row per customer: CustomerID, Age, City, SignupDate, CustomerSegment | 10,000 |
| `orders.csv` | One row per order line: OrderID, CustomerID, OrderDate, ProductID, Quantity, Discount, PaymentMethod, Status | 50,120 |
| `payments.csv` | One row per payment attempt: PaymentID, OrderID, PaymentDate, PaymentStatus | 50,000 |
| `products.csv` | The 20 products the shop sells: ProductID, ProductName, Category, UnitPrice | 20 |

The files connect through three keys: orders link to customers through `CustomerID`, to products through `ProductID`, and to payments through `OrderID`.

---

## 🔄 From Data to Insights

```
Raw data (4 files)
      ↓
Inspect each table (rows, columns, data types)
      ↓
Clean (missing values, duplicates, invalid values, inconsistent text, broken links)
      ↓
Join orders to customers, products and payments (left joins, row counts checked)
      ↓
Create new columns (Revenue, Year, Month, YearMonth)
      ↓
Answer the business questions (groupby totals, averages, counts, percentages)
      ↓
Build the Looker Studio dashboard
      ↓
Insights and recommendations
```

### 🧹 Data Cleaning Decisions

| Table | Problem found | What I did |
|---|---|---|
| Customers | Missing ages | Filled with the average age |
| Customers | Missing cities, and the text "None" | Set to "Unknown" |
| Customers | Same city spelled in different ways (tehran / Tehran, Mashad / Mashhad) | Standardised to Tehran and Mashhad |
| Customers | SignupDate stored as text | Converted to a date |
| Payments | 35 missing payment dates (all Paid) | Left blank, because a made-up date would distort the trend |
| Orders | 120 fully duplicated rows | Removed |
| Orders | 25 rows with a quantity of 0 or below | Removed, because they are invalid |
| Orders | 80 missing quantities | Set to 1, the most common quantity |
| Orders | 221 missing discounts | Set to 0 (no discount recorded) |
| Orders | 452 missing payment methods | Set to "Unknown" |
| Orders | 35 missing order dates | Left blank: excluded from the monthly trend, kept in the totals |
| Orders | 30 orders under CustomerID 999999, which is not in the customer list | Kept and labelled "No customer record", so revenue stays complete |

After cleaning and joining, the combined table has **49,975 rows and 18 columns**, with no rows lost or duplicated by the joins.

### 💰 Revenue Definition

`Revenue = Quantity × UnitPrice × (1 − Discount)`, counted **only for orders that are Completed and Paid**. Cancelled, returned, failed and refunded orders mean the shop did not keep the money.

---

## 📊 Dashboard (Looker Studio)

| Page | What it shows |
|---|---|
| 1. Summary | KPI cards (total revenue, number of orders, average order value) and the three key findings |
| 2. Revenue Trend | Monthly revenue line chart with a "So what?" |
| 3. Products and Categories | Revenue by category, and top 5 products by revenue against top 5 by units |
| 4. Customers | Revenue by city, revenue by customer segment, and average order value by segment |
| 5. Order Problems and Discounts | Order status, payment status, failed payment rate by method, and order value by discount |
| 6. Recommendations and Data Notes | Three recommendations and the data problems found |

**Screenshots:** [add 2 or 3 dashboard screenshots here]

---

## 💡 Key Insights

- **Total revenue is 2,994,604.45 from 42,825 orders**, with an average order value of 69.93.
- **Revenue was flat, then fell.** It held at roughly 95,000 to 115,000 a month until January 2026, then dropped by about a third to 65,000 to 75,000. The cause is fewer orders (about 1,500 a month down to about 1,000), not smaller orders or more cancellations. There is no repeating seasonal peak.
- **Revenue is concentrated.** Electronics brings in 51% of revenue. Tehran alone brings in 28%, and Tehran, Mashhad and Karaj together bring in about half.
- **Volume and revenue tell different stories.** The best sellers by units (Notebook, Phone Case, USB-C Cable, HDMI Cable, Wireless Mouse) are cheap, and none of them is in the top 5 by revenue (Headphones, Office Chair, Tablet, Smart Watch, Microphone).
- **Regular customers bring in 55% of revenue.** VIP customers are the smallest group (about 10%) and spend slightly less per order (68.11 against about 70).
- **8.0% of orders are cancelled or returned** (4.9% and 3.1%), and **3.8% of payments fail**. Every payment method fails at about the same rate (3.6% to 3.9%).
- **Bigger discounts do not make bigger orders.** Customers buy about 1.9 items per order at every discount level, while average order value falls from 74.52 with no discount to 56.10 at 30% off.

---

## ✅ Recommendations

1. **Find out why orders fell in 2026 and win those customers back.** Orders dropped from about 1,500 a month to about 1,000 from February 2026. Recovering about 500 orders a month would bring back about 35,000 in monthly revenue.
2. **Test lower discounts before cutting them.** Deep discounts (20% and 30%) apply to about 11% of orders and do not increase order size. A trial on a few products would show whether they bring in extra orders.
3. **Reduce failed and cancelled orders at checkout.** Failures are spread evenly across payment methods, so the fix belongs in the checkout process (payment reminders, retry prompts), not in dropping one method.

---

## 🧠 Skills Demonstrated

- Data cleaning in Python (missing values, duplicates, invalid values, inconsistent text, broken links)
- Joining tables and checking row counts to avoid duplicated or lost rows
- Creating calculated columns and defining a clear revenue rule
- Aggregating data with `groupby` to answer business questions
- Choosing the right chart for each question and designing a clean dashboard
- Writing for a non-technical audience with a "So what?" for every chart
- Documenting cleaning decisions and assumptions so every number can be traced

---

## 🚀 End-to-End Journey

1. **Understood the brief** and the business questions
2. **Explored the four tables** to learn what each row represents
3. **Cleaned each table** and wrote down every decision
4. **Joined the tables** and checked the row count after each join
5. **Created Revenue, Year, Month and YearMonth** columns
6. **Answered the six business questions** with tables
7. **Built the dashboard** in Looker Studio, checking every total against the notebook
8. **Wrote the story:** a summary page, "So what?" sentences and three recommendations

---

## 📦 Deliverables

- [x] Cleaned and combined dataset
- [x] Python notebook with the cleaning, joins and analysis
- [x] List of cleaning decisions
- [x] 6-page Looker Studio dashboard
- [x] Three recommendations backed by numbers
- [x] This README

---

## 🏁 Outcome

The analysis shows a shop with steady revenue until early 2026, when a sharp fall in order volume cut monthly revenue by about a third. It also shows where the money comes from (Electronics, a few large cities and Regular customers), that discounts lower the value of each order without making orders larger, and that payment failures are not tied to any one payment method. The three recommendations turn these findings into actions the Head of Operations can start on.

---

## 🔮 Future Improvements

- Look into the February 2026 drop with extra data such as marketing activity, stock levels and website changes
- Check how many customers each city has, to see whether Tehran leads because of more customers or higher spending
- Run a small discount trial to measure whether discounts bring in extra orders
- Verify the Monitor's unit price, which looks low for a monitor (about 20) [keep this line only if you confirmed it]
- Rebuild the dashboard in Power BI to compare the two tools

---

## 👤 Author

**Lerato Legodi**
GitHub: [LeratoNope](https://github.com/LeratoNope)
LinkedIn: [add your LinkedIn link here]

*Case study provided by the BrightLearn Data Analytics Program.*

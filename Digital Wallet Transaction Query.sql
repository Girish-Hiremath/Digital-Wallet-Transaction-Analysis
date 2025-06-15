-- 📊 Analyze Spending Behavior (Categories, Merchants, Regions)
use digitaltransaction;
 
 
-- 1	What are the top 5 product categories by total transaction amount?
select product_category, sum(product_amount) from dwt
group by product_category
order by product_category desc
limit 5;
-- 2	Which merchants have the highest average transaction value?

select merchant_name, sum(product_amount) from dwt
group by merchant_name
order by merchant_name desc
limit 5;

-- 3	What is the total transaction amount by region/location?

select location, sum(product_amount) from dwt
group by location
order by location desc;

-- 4	How many unique users transacted in each product category?

select product_name, count( distinct User_id) as Users from dwt
group by product_name
order by  Users desc;

-- 	💰 Evaluate Cashback & Loyalty Points

-- 5	Which users received the highest total cashback and loyalty points?

select user_id, sum(cashback) as cb, sum(loyalty_points) as lp from dwt
group by user_id 
order by lp desc;

-- 6	Is there a difference in transaction frequency between users who receive rewards and those who don't?


SELECT CASE 
        WHEN SUM(cashback) > 0 OR SUM(loyalty_points) > 0 THEN 'Rewarded Users'
        ELSE 'Non-Rewarded Users'
    END AS user_id,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT user_id) AS total_users,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT user_id), 2) AS avg_transactions_per_user
FROM dwt
GROUP BY user_id;

-- 7  What is the average cashback earned per product category?


select product_category, avg(cashback) as avgcb from dwt
group by product_category
order by avgcb desc;

-- 8	How do loyalty points earned affect user retention over time?


-- 	📉 Identify Transaction Failure Patterns
-- 9	What is the failure rate of transactions by payment method?

select   payment_method,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate_percent
FROM dwt
GROUP BY payment_method;

-- 10	Which device types are associated with the most failed transactions?
select * from dwt;
select   device_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate_percent
FROM dwt
GROUP BY device_type
order by failed_transactions desc;


-- 11	Are there specific merchants with unusually high failure rates?
select   merchant_name,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate_percent
FROM dwt
GROUP BY merchant_name
order by failed_transactions desc;


-- 12	What is the trend in failure rate over the last 6 months?
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS failure_rate_percent
FROM dwt
WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY txn_month;

-- 	📅 Discover Seasonal & Temporal Trends
-- 13	What is the total number of transactions per month in the last year?

select * from dwt;
SELECT
    DATE_FORMAT(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i'), '%Y-%m') AS txn_month,
    COUNT(*) AS total_transactions
FROM dwt
WHERE STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i') >= CURDATE() - INTERVAL 12 MONTH
GROUP BY DATE_FORMAT(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i'), '%Y-%m')
ORDER BY txn_month;

-- 14	How does daily transaction volume vary across days of the week?

SELECT 
    DAYNAME(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')) AS day_of_week,
    COUNT(*) AS total_transactions
FROM dwt
GROUP BY day_of_week
ORDER BY field (day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- 15	What are the busiest hours of the day for transactions?
SELECT 
    hour(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')) AS hour_of_the_day,
    COUNT(*) AS total_transactions
FROM dwt
GROUP BY hour_of_the_day
order by total_transactions desc ;


-- 16	Are there specific months where certain product categories see a spike in transactions?
SELECT 
   month(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')) AS month_of_the_year,
    COUNT(*) AS total_transactions
FROM dwt
GROUP BY month_of_the_year
order by total_transactions desc ;

-- 🚨 Detect Anomalies or Fraud Patterns

-- 17	Which users have an unusually high number of failed transactions?
select * from dwt;

select user_id, count(*) as failed_transaction from dwt
where transaction_status = 'failed'
group by user_id
HAVING COUNT(*) > 0
order by user_id desc;

-- 18	Are there transactions with unusually high product amounts that may indicate fraud?\
select * from dwt;

SELECT *
FROM dwt
WHERE product_amount > (
    SELECT AVG(product_amount) + 2 * STDDEV(product_amount)
    FROM dwt
);

-- 19	Are there users performing many small, rapid transactions in a short period?
select * from dwt;

SELECT 
    user_id,
    COUNT(*) AS txn_count,
    MIN(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')) AS first_txn_time,
    MAX(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')) AS last_txn_time,
    TIMESTAMPDIFF(MINUTE, 
        MIN(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i')),
        MAX(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i'))
    ) AS time_diff_minutes
FROM dwt
WHERE product_amount < 100
GROUP BY user_id, DATE(STR_TO_DATE(transaction_date, '%d-%m-%Y %H:%i'))
HAVING txn_count >= 1 AND time_diff_minutes <= 60
ORDER BY txn_count DESC;

-- 20	Are there merchants consistently involved in failed high-value transactions?
select merchant_name, count(*) as tt from dwt
where transaction_status = 'failed' and
product_amount > (
    SELECT AVG(product_amount) 
    from dwt)
    group by merchant_name
    order by tt desc;


-- 	👥 Segment Users for Marketing/Optimization
-- 21	Can users be grouped by average transaction amount and frequency?

select user_id, count(*) as avgta , avg(product_amount) as avgpa from dwt
where transaction_status ='Successful'
group by user_id;

-- 22	How many users consistently transact across multiple product categories?

SELECT user_id, COUNT(DISTINCT product_category) AS category_count FROM dwt
WHERE transaction_status = 'Successful'
GROUP BY user_id
HAVING category_count >= 3;


-- 23	What are the characteristics of high-value vs. low-value users?
WITH user_summary AS (
    SELECT 
        user_id,
        COUNT(*) AS txn_count,
        ROUND(AVG(product_amount), 2) AS avg_amount,
        SUM(cashback) AS total_cashback,
        SUM(loyalty_points) AS total_points,
        COUNT(DISTINCT product_category) AS category_diversity
    FROM dwt
    WHERE transaction_status = 'Successful'
    GROUP BY user_id
),
value_segments AS (
    SELECT *,
        CASE 
            WHEN avg_amount >= 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS user_value_segment
    FROM user_summary
)
SELECT 
    user_value_segment,
    ROUND(AVG(txn_count), 2) AS avg_txns,
    ROUND(AVG(avg_amount), 2) AS avg_txn_amount,
    ROUND(AVG(total_cashback), 2) AS avg_cashback,
    ROUND(AVG(total_points), 2) AS avg_loyalty_points,
    ROUND(AVG(category_diversity), 2) AS avg_categories_used
FROM value_segments
GROUP BY user_value_segment;


-- 24	How do transaction patterns vary across different device types and regions for user segments?
select * from dwt;

WITH user_segments AS (SELECT user_id, COUNT(*) AS txn_count, AVG(product_amount) AS avg_amount,
        CASE
            WHEN COUNT(*) > 50 AND AVG(product_amount) > 1000 THEN 'High Value & Frequent'
            WHEN COUNT(*) > 50 THEN 'Frequent Spender'
            WHEN AVG(product_amount) > 1000 THEN 'High Value, Infrequent'
            ELSE 'Low Value & Infrequent'
        END AS user_segment FROM dwt
    WHERE transaction_status = 'Successful'
    GROUP BY user_id
)

SELECT 
    us.user_segment,
    d.device_type,
    d.location,
    COUNT(*) AS total_txns,
    ROUND(AVG(d.product_amount), 2) AS avg_amount
FROM dwt d
JOIN user_segments us ON d.user_id = us.user_id
WHERE d.transaction_status = 'Successful'
GROUP BY us.user_segment, d.device_type, d.location
ORDER BY us.user_segment, total_txns DESC;


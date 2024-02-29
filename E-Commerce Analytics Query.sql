-- Q1 Find the most popular product category in each city based on the number of orders.
WITH CityOrderCounts AS (
    SELECT gl.geolocation_city, p.product_category_name, COUNT(o.order_id) AS order_count,
           RANK() OVER(PARTITION BY gl.geolocation_city ORDER BY COUNT(o.order_id) DESC) AS rank_order_count
    FROM ORDERS o
    INNER JOIN ORDER_ITEMS oi ON o.order_id = oi.order_id
    INNER JOIN PRODUCTS p ON oi.product_id = p.product_id
    INNER JOIN SELLERS s ON oi.seller_id = s.seller_id
    INNER JOIN GEO_LOCATION gl ON s.seller_zip_code_prefix = gl.geolocation_zip_code_prefix
    GROUP BY gl.geolocation_city, p.product_category_name
)
SELECT geolocation_city, product_category_name, order_count
FROM CityOrderCounts
WHERE rank_order_count = 1
ORDER BY order_count DESC;

-- Q2 Find the top 5 best-selling products based on the quantity sold
WITH product_sales AS (
    SELECT ot.product_id, p.product_category_name,
           count(ot.order_item_id) AS total_quantity_sold,
           ROW_NUMBER() OVER (ORDER BY count(ot.order_item_id) DESC) AS sales_rank
    FROM ORDERS O
    INNER JOIN ORDER_ITEMS ot ON ot.order_id = O.order_id
    INNER JOIN products p ON ot.product_id = p.product_id
    GROUP BY ot.product_id, p.product_category_name
)
SELECT product_id, product_category_name, total_quantity_sold
FROM product_sales
WHERE sales_rank <= 5
ORDER BY total_quantity_sold DESC;

-- Q3 Retrieve the top 10 customers who made the highest total payments
WITH customer_payments AS (
    SELECT c.customer_id, c.customer_city, SUM(op.payment_value) AS total_payments,
           ROW_NUMBER() OVER (ORDER BY SUM(op.payment_value) DESC) AS payment_rank
    FROM CUSTOMERS c
    INNER JOIN ORDERS o ON c.customer_id = o.customer_id
    INNER JOIN ORDER_PAYMENTS op ON o.order_id = op.order_id
    GROUP BY c.customer_id, c.customer_city
)
SELECT customer_id, customer_city, total_payments
FROM customer_payments
WHERE payment_rank <= 10
ORDER BY total_payments DESC;

-- Q4 Find the products with the highest average review scores by category.
WITH AvgReviewScores AS (
    SELECT
        p.product_category_name,
        -- p.product_id,
        AVG(orr.review_score) AS avg_review_score
    FROM PRODUCTS p
    INNER JOIN ORDER_ITEMS oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN ORDER_REVIEW_RATINGS orr ON o.order_id = orr.order_id
    WHERE p.product_category_name <> '#N/A'
    GROUP BY p.product_category_name-- , p.product_id
)
SELECT
    product_category_name,
    -- product_id,
    FIRST_VALUE(avg_review_score) OVER (
        PARTITION BY product_category_name
        ORDER BY avg_review_score DESC
    ) AS avg_review_score
FROM AvgReviewScores
ORDER BY avg_review_score DESC;

-- Q5 Find the products with the highest payment values.
WITH MaxPaymentPerProduct AS (
    SELECT
        distinct p.product_id,
        p.product_category_name,
        MAX(op.payment_value) AS highest_payment_value
    FROM ORDER_PAYMENTS op
    INNER JOIN order_items ot ON ot.order_id = op.order_id
    INNER JOIN products p ON p.product_id = ot.product_id
    GROUP BY p.product_id, p.product_category_name
)
SELECT
    distinct product_id,
    product_category_name,
    highest_payment_value
FROM MaxPaymentPerProduct
ORDER BY highest_payment_value DESC
LIMIT 10;

-- Q6 List the cities where customers made more than three orders in a single day.
SELECT gl.geolocation_city, o.order_purchase_timestamp, COUNT(o.order_id) AS order_count
FROM ORDERS o
inner join customers c on c.customer_id = o.customer_id
INNER JOIN GEO_LOCATION gl ON c.customer_zip_code_prefix = gl.geolocation_zip_code_prefix
GROUP BY  o.order_purchase_timestamp, gl.geolocation_city
HAVING COUNT(o.order_id) > 3;

-- Q7 Calculate the total revenue generated for each orders.
SELECT order_id,
	SUM(price + freight_value) OVER(PARTITION BY order_id) AS Total_Revenue
FROM order_items 
ORDER BY Total_Revenue DESC;

-- Q8 Identify sellers who have received both high and low ratings on their products.
SELECT s.seller_id, AVG(orr.review_score) AS avg_rating
FROM SELLERS s
INNER JOIN ORDER_ITEMS oi ON s.seller_id = oi.seller_id
inner join orders o on o.order_id = oi.order_id
inner join ORDER_REVIEW_RATINGS orr ON orr.order_id = o.order_id
GROUP BY s.seller_id
HAVING MAX(orr.review_score) > 4 AND MIN(orr.review_score) < 2
order by avg_rating desc;




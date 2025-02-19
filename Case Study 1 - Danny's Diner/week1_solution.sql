
----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------

-- Author: Sivaranjani P
-- Tool used: MySQL Server

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, 
    SUM(m.price) AS Amount_Spent
FROM sales s
JOIN menu m 
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER by s.customer_id;
  

-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id, 
    COUNT(DISTINCT ORDER_DATE) AS Days_Visited
FROM sales 
GROUP BY customer_id;

-- 3. what was the first item from the menu purchased by each customer?
WITH sales_order_cte AS
(
SELECT 
	s.customer_id, 
    s.order_date,
    s.product_id, 
    m.product_name,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as order_rank 
FROM sales s 
JOIN menu m 
	ON s.product_id = m.product_id
)
SELECT 
	DISTINCT customer_id, 
    product_name 
FROM sales_order_cte
WHERE 
	order_rank = 1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	s.product_id, 
    m.product_name,
    count(*) AS no_of_times_bought
FROM sales s  
JOIN menu m 
	ON s.product_id = m.product_id
GROUP BY 
	s.product_id, m.product_name
ORDER BY 
	no_of_times_bought DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH favs_cte AS
(
SELECT 
	s.customer_id,  
    m.product_name, 
    COUNT(*) AS order_count,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS fav_rank
FROM sales s 
JOIN menu m 
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT
	customer_id,
    product_name,
    order_count
FROM favs_cte
WHERE fav_rank=1;

-- 6.Which item was purchased first by the customer after they became a member?
WITH member_order_cte AS
(
SELECT 
	s.customer_id, 
    m.join_date,
    s.order_date,
    me.product_name,
    RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS order_rank
FROM sales s
JOIN members m 
	ON s.customer_id = m.customer_id
JOIN menu me 
	ON s.product_id = me.product_id
WHERE s.order_date > m.join_date
)
SELECT 
	customer_id, 
    product_name
FROM member_order_cte 
WHERE order_rank = 1;

-- 7.Which item was purchased just before the customer became a member?
WITH PRIOR_ORDER_CTE AS
(
SELECT 
	s.customer_id, 
    s.order_date, 
    m.join_date,
    me.product_name,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS prior_order_rank
FROM
	sales s 
JOIN members m 
	ON s.customer_id = m.customer_id
JOIN menu me
	ON s.product_id = me.product_id
WHERE 
	s.order_date < m.join_date
)
SELECT 
	DISTINCT customer_id, 
    product_name
FROM prior_order_cte 
WHERE prior_order_rank = 1;

-- 8.What is the total items and amount spent for each member before they became a member?
SELECT 
	m.customer_id, 
    COUNT(*) as total_items, 
    SUM(menu.price) as total_amount
FROM members m
JOIN sales s 
	ON m.customer_id = s.customer_id
    AND s.order_date < m.join_date 
JOIN menu 
	ON menu.product_id = s.product_id
GROUP BY m.customer_id
ORDER BY m.customer_id;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
WITH point_cte AS(
SELECT 
	s.customer_id, 
    me.product_name, 
    SUM(me.price) as Total_$_Spent, 
    CASE 
		WHEN me.product_name = "sushi" then SUM(me.price)*10*2
		ELSE SUM(me.price)*10 
    END AS Points_earned
FROM sales s 
JOIN menu me 
	ON s.product_id = me.product_id
GROUP BY s.customer_id, me.product_name
)
SELECT 
	customer_id, 
    SUM(Points_earned) AS total_points_earned
FROM point_cte
GROUP BY customer_id;

-- 10.In the first week after a customer joins the program 
-- (including their join date)
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH points_cte AS 
(
SELECT 
	m.customer_id, 
    m.join_date,
    s.order_date,
    me.product_name, 
    me.price, 
    CASE 
		WHEN s.order_date between m.join_date AND date_add(m.join_date, INTERVAL 7 DAY) then me.price*10*2
		ELSE me.price*10
    END AS points_earned
FROM members m 
JOIN sales s ON m.customer_id = s.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE s.order_date <= date("2021-01-31")
)
SELECT 
	customer_id, 
    SUM(points_earned)
FROM points_cte
GROUP BY customer_id;


-- Bonus questions
-- 1. show customer_id, order_date, product_name, price, member? as a result
SELECT
	s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
		WHEN s.order_date >= m.join_date then 'Y'
		ELSE 'N'
	END AS 'member?'
FROM sales s 
LEFT JOIN members m 
	ON s.customer_id = m.customer_id
JOIN menu me 
	ON s.product_id = me.product_id
ORDER BY s.customer_id, s.order_date;

-- 2. show customer_id, order_date, product_name, price, member? as a result
-- along with rankings only for member purchases otherwise NULL
WITH info_cte AS 
(
SELECT
	s.customer_id,
    s.order_date,
    me.product_name,
    me.price,
    CASE
		WHEN s.order_date >= m.join_date then 'Y'
		ELSE 'N'
	END AS is_member
FROM sales s 
LEFT JOIN members m 
	ON s.customer_id = m.customer_id
JOIN menu me 
	ON s.product_id = me.product_id
ORDER BY s.customer_id, s.order_date
)
SELECT
	*,
    CASE 
		WHEN is_member = 'Y' THEN 
			RANK() OVER (PARTITION BY customer_id, is_member ORDER BY order_date)
		ELSE NULL
	END AS rankings
FROM info_cte;

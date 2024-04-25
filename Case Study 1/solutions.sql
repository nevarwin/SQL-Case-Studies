-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount_spent
FROM dannys_diner.sales s
JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, SUM(DAY(s.order_date)) as days
FROM dannys_diner.sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer? NOT WORKING
SELECT
  s.customer_id,
  MIN(s.order_date) AS first_order_date,
  m.product_name
FROM
  dannys_diner.menu m
JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY
  s.customer_id,
  m.product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name as Most_purchased_item, COUNT(s.customer_id) as Total_item_purchased
FROM dannys_diner.menu m
JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY m.product_name	
ORDER BY COUNT(s.customer_id) DESC;

-- 5. Which item was the most popular for each customer?
SELECT m.product_name as Most_purchased_item, COUNT(s.customer_id) as Total_item_purchased
FROM dannys_diner.menu m
JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY COUNT(s.customer_id) DESC;

-- 6. Which item was purchased first by the customer after they became a member?
WITH RankedSales AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    mem.join_date,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
  FROM
    dannys_diner.sales s
  JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
  JOIN
    dannys_diner.members mem ON s.customer_id = mem.customer_id
  WHERE
    mem.join_date < s.order_date
)
SELECT
  customer_id,
  product_name,
  order_date,
  join_date
FROM
  RankedSales
WHERE
  rn = 1;


-- 7. Which item was purchased just before the customer became a member?
WITH RankedSales AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    mem.join_date,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
  FROM
    dannys_diner.sales s
  JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
  JOIN
    dannys_diner.members mem ON s.customer_id = mem.customer_id
  WHERE
    mem.join_date > s.order_date
  ORDER BY
    s.customer_id ASC
)
SELECT
  customer_id,
  product_name,
  order_date,
  join_date
FROM
  RankedSales;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH PreMembershipSales AS (
  SELECT
    s.customer_id,
    SUM( m.price) as total_amount_spent,
    COUNT(s.product_id) as total_items
  FROM
    dannys_diner.sales s
  JOIN
    dannys_diner.menu m ON s.product_id = m.product_id
  JOIN
    dannys_diner.members mem ON s.customer_id = mem.customer_id
  WHERE
    s.order_date < mem.join_date
  GROUP BY
  	s.customer_id
)
SELECT
  customer_id,
  total_items,
  total_amount_spent
FROM
  PreMembershipSales;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH MemberPoints AS (
	SELECT 
  		s.customer_id,
  		COUNT(s.product_id) AS total_items,
  		SUM(m.price) AS total_amount_spent,
  		SUM(
        	CASE
          		WHEN m.product_id = 2 THEN m.price*20
          		ELSE m.price*10
          	END
        ) AS total_points
  	FROM 
  		dannys_diner.sales s
  	JOIN
  		dannys_diner.menu m ON s.product_id = m.product_id
  	GROUP BY
  		s.customer_id
)
SELECT
	customer_id
    total_items,
    total_amount_spent,
    total_points
FROM
	MemberPoints
ORDER BY
	customer_id ASC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH MemberPoints AS (
	SELECT 
  		s.customer_id,
  		COUNT(s.product_id) AS total_items,
  		SUM(m.price) AS total_amount_spent,
  		SUM(m.price*20) AS total_points
  	FROM 
  		dannys_diner.sales s
  	JOIN
  		dannys_diner.menu m ON s.product_id = m.product_id
  	JOIN
    dannys_diner.members mem ON s.customer_id = mem.customer_id
  	WHERE 
  		s.customer_id <> 'C' AND
  		EXTRACT(MONTH FROM s.order_date) = 1
  	GROUP BY
  		s.customer_id
)
SELECT
    customer_id,
    total_items,
    total_amount_spent,
    total_points
FROM
	MemberPoints
ORDER BY
	customer_id ASC;

--BONUS QUESTIONS
--Join All The Things
WITH Membership AS (
	SELECT 
  		c.customer_id,
  		TO_CHAR(s.order_date, 'YYYY-MM-DD') as order_date,
  		m.product_name,
  		m.price,
  		CASE
			WHEN s.order_date < mem.join_date THEN 'N'
			WHEN mem.join_date IS NULL THEN 'N'
  			ELSE 'Y'
 		END AS member
  	FROM 
  		(SELECT DISTINCT customer_id FROM dannys_diner.sales) c
  	LEFT JOIN
  		dannys_diner.sales s ON c.customer_id = s.customer_id
  	LEFT JOIN
  		dannys_diner.menu m ON s.product_id = m.product_id
  	LEFT JOIN
  		dannys_diner.members mem ON c.customer_id = mem.customer_id
)
SELECT
	customer_id,
    order_date,
  	product_name,
  	price,
    member
FROM
	Membership
ORDER BY
	customer_id ASC,
	order_date ASC;

-- Rank All The Things
WITH Membership AS (
	SELECT 
  		c.customer_id,
  		TO_CHAR(s.order_date, 'YYYY-MM-DD') as order_date,
  		m.product_name,
  		m.price,
  		CASE
			WHEN s.order_date < mem.join_date THEN 'N'
  			WHEN mem.join_date IS NULL THEN 'N'
  			ELSE 'Y'
 		END AS member
  	FROM 
  		(SELECT DISTINCT customer_id FROM dannys_diner.sales) c
  	
)
SELECT
	customer_id,
    order_date,
  	product_name,
  	price,
    member,
CASE
  	WHEN member = 'Y' THEN ROW_NUMBER() OVER (PARTITION BY customer_id, member ORDER BY order_date)
END AS Ranking
FROM
	Membership
ORDER BY
	customer_id ASC,
    order_date ASC;

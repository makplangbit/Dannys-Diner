-- 1. What is the total amount each customer spent at the restaurant?
SELECT Customer_id,
       SUM(price) AS Total_spent
FROM Sales AS S
INNER JOIN Menu AS M ON S.Product_id = M.Product_id
GROUP BY Customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT Customer_id,
       COUNT(DISTINCT(order_date)) AS number_of_visits
FROM Sales
GROUP BY Customer_id;

-- 3. What was the first item from the menu purchased by each customer?			 
WITH ranked_orders AS (
SELECT Customer_id,
       Product_name,
	   order_date,
	   RANK() OVER(PARTITION BY Customer_id ORDER BY order_date ASC) AS rank
FROM Sales AS S
INNER JOIN Menu AS M 
           ON S.Product_id = M.Product_id
)	
SELECT Customer_id, Product_name, order_date
FROM ranked_orders
WHERE rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,
       COUNT(order_date) AS number_of_orders
FROM Sales AS S
INNER JOIN Menu AS M
       ON S.Product_id = M.Product_id
GROUP BY product_name
ORDER BY COUNT(order_date) DESC;

-- 5. Which item was the most popular for each customer?
WITH product_orders AS (
  SELECT customer_id,
       product_name,
       COUNT(order_date) AS orders,
	   RANK() OVER(PARTITION BY customer_id ORDER BY  COUNT(order_date)) AS popular_product
FROM Sales AS S
INNER JOIN Menu AS M
      ON S.Product_id = M.Product_id
GROUP BY customer_id, product_name
)
SELECT customer_id, product_name
FROM product_orders
WHERE popular_product = 1;

-- 6. Which item was purchased first by the customer after they became a member?
 WITH ranked_orders AS (
SELECT S.Customer_id,
        join_date,
		order_date,
		Product_name,
	    RANK() OVER(PARTITION BY S.customer_id ORDER BY (order_date)) AS Customers_first_purchase
FROM Sales AS S
      INNER JOIN Members AS B
            ON S.Customer_id= B.Customer_id
      INNER JOIN Menu AS M
            ON S.Product_id = M.Product_id
	  WHERE S.order_date >= B.join_date
)
SELECT Customer_id, join_date, order_date, Product_name
FROM ranked_orders
WHERE Customers_first_purchase = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH ranked_orders AS (
SELECT S.Customer_id,
        join_date,
		order_date,
		Product_name,
	    RANK() OVER(PARTITION BY S.customer_id ORDER BY (order_date)DESC) AS Customers_first_purchase
   FROM Sales AS S
      INNER JOIN Members AS B
            ON S.Customer_id= B.Customer_id
      INNER JOIN Menu AS M
            ON S.Product_id = M.Product_id
	  WHERE S.order_date < B.join_date
   )
SELECT Customer_id, join_date, order_date, Product_name
FROM ranked_orders
WHERE Customers_first_purchase = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT S.Customer_id,
	   COUNT(Product_name) AS Total_items_bought,
	   SUM(Price) AS Total_amount
FROM Sales AS S
      INNER JOIN Members AS B
            ON S.Customer_id= B.Customer_id
      INNER JOIN Menu AS M
            ON S.Product_id = M.Product_id
	  WHERE S.order_date < B.join_date
GROUP BY S.Customer_id;
       
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT Customer_id,   
   SUM(CASE 
        WHEN M.Product_name = 'sushi' THEN M.Price * 2 * 10
        ELSE M.Price * 10
    END) AS Points	   
FROM Sales AS S
INNER JOIN Menu AS M
           ON S.Product_id=M.Product_id
GROUP BY Customer_id;
		      
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
	
	WITH Points AS (
SELECT 
  S.Customer_id,
  CASE 
    WHEN S.order_date BETWEEN B.join_date AND B.join_date + INTERVAL '7 day' 
    THEN M.Price * 2 * 10
    ELSE M.Price * 10
  END AS Points
FROM 
  Sales AS S
  INNER JOIN Menu AS M
  ON S.Product_id = M.Product_id
  INNER JOIN Members AS B
  ON S.Customer_id = B.Customer_id
WHERE 
  EXTRACT(MONTH FROM S.order_date) = 1 AND
  EXTRACT(YEAR FROM S.order_date) = EXTRACT(YEAR FROM B.join_date) AND
  S.Customer_id IN ('A', 'B')
)
SELECT 
  Customer_id,
  SUM(Points) AS Total_points
FROM 
  Points
GROUP BY
  Customer_id; 
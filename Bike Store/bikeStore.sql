-- Number of fields(columns) in tables
SELECT TABLE_NAME,
	   COUNT(*) AS Number_of_Fields
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('brands', 'categories', 'customers', 'order_items', 'orders', 'products', 'staffs', 'stocks', 'stores')
GROUP BY TABLE_NAME;


-- Name of the fields in tables
SELECT TABLE_NAME,
	   GROUP_CONCAT(COLUMN_NAME SEPARATOR',  ') AS Column_Names
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('brands', 'categories', 'customers', 'order_items', 'orders', 'products', 'staffs', 'stocks', 'stores')
GROUP BY TABLE_NAME;


-- Number of data for each table and each column to see if null values exist (try to change column part to dynamic query)
SELECT COUNT(*), COUNT(brand_id), COUNT(brand_name)
FROM brands;

SELECT COUNT(*), COUNT(category_id), COUNT(category_name)
FROM categories;

	-- 'phone' field has null values (Table has 1445 values. But 'phone' has 178 non-null values.)
SELECT COUNT(*), COUNT(customer_id), COUNT(first_name), COUNT(last_name), COUNT(phone),
		COUNT(email), COUNT(street), COUNT(city), COUNT(state), COUNT(zip_code)
FROM customers;

SELECT COUNT(*), COUNT(order_id), COUNT(item_id), COUNT(product_id), COUNT(quantity), COUNT(list_price), COUNT(discount)
FROM order_items;

	-- 'shipped_date' field has null values (Table has 1615 values. But 'shipped_date' has 1445 non-null values.)
SELECT COUNT(*), COUNT(order_id), COUNT(customer_id), COUNT(order_status), COUNT(order_date),
		COUNT(required_date), COUNT(shipped_date), COUNT(store_id), COUNT(staff_id)
FROM orders;

SELECT COUNT(*), COUNT(product_id), COUNT(product_name), COUNT(brand_id),
		COUNT(category_id), COUNT(model_year), COUNT(list_price)
FROM products;

	-- 'manager_id' field has null value (Table has 10 values. But 'manager_id' has 9 non-null values.)
SELECT COUNT(*), COUNT(staff_id), COUNT(first_name), COUNT(last_name), COUNT(email),
		COUNT(phone), COUNT(active), COUNT(store_id), COUNT(manager_id)
FROM staffs;

SELECT COUNT(*), COUNT(store_id), COUNT(product_id), COUNT(quantity)
FROM stocks;

SELECT COUNT(*), COUNT(store_id), COUNT(store_name), COUNT(phone), COUNT(email),
		COUNT(street), COUNT(city), COUNT(state), COUNT(zip_code)
FROM stores;


-- States and number of cities in each state that orders are given from
SELECT COALESCE(state, 'TOTAL') AS state,
	   COUNT(DISTINCT city) AS Number_of_Cities
FROM customers
GROUP BY state WITH ROLLUP;


-- 	Number of orders by state and city
SELECT customers.state,
	   customers.city,
       COUNT(*) AS number_of_orders
FROM orders
LEFT JOIN customers
	ON orders.customer_id = customers.customer_id
GROUP BY customers.state, customers.city
ORDER BY customers.state, number_of_orders DESC;


-- Cities in each state from which maximum amount of orders are given
SELECT state,
	   city,
	   order_count
FROM (
	   SELECT customers.state,
			  customers.city,
              COUNT(*) AS order_count,
              MAX(COUNT(*)) OVER (PARTITION BY customers.state) AS state_max_order_count,
              MIN(COUNT(*)) OVER(PARTITION BY customers.state) AS state_min_order_count
	   FROM orders
	   LEFT JOIN customers
		   ON orders.customer_id = customers.customer_id
	   GROUP BY customers.state, customers.city
	 ) AS num_of_orders_by_city
WHERE order_count = state_max_order_count;


-- Cities in each state from which minimum amount of orders are given
SELECT state,
	   city,
       order_count
FROM (
	   SELECT customers.state,
			  customers.city,
              COUNT(*) AS order_count,
              MAX(COUNT(*)) OVER (PARTITION BY customers.state) AS state_max_order_count,
              MIN(COUNT(*)) OVER(PARTITION BY customers.state) AS state_min_order_count
		FROM orders
        LEFT JOIN customers
			ON orders.customer_id = customers.customer_id
		GROUP BY customers.state, customers.city
	 ) AS num_of_orders_by_city
WHERE order_count = state_min_order_count;


-- Number of orders by order status for all orders
SELECT COALESCE(CASE
					WHEN order_status = 1 THEN 'Pending'
					WHEN order_status = 2 THEN 'Processing'
					WHEN order_status = 3 THEN 'Rejected'
					WHEN order_status = 4 THEN 'Completed'
				END, 'TOTAL') AS order_status_text,
        COUNT(*) AS number_of_orders
FROM orders
GROUP BY order_status WITH ROLLUP
ORDER BY number_of_orders;


-- Number of orders by order status for each store
SELECT COALESCE(stores.store_name, 'ALL STORES') AS store_name,
	   COALESCE(CASE
					WHEN orders.order_status = 1 THEN 'Pending'
					WHEN orders.order_status = 2 THEN 'Processing'
					WHEN orders.order_status = 3 THEN 'Rejected'
					WHEN orders.order_status = 4 THEN 'Completed'
				END, 'TOTAL ORDERS') AS order_status_text,
	   COUNT(*) AS number_of_orders
FROM orders
LEFT JOIN stores
	ON orders.store_id = stores.store_id
GROUP BY stores.store_name, orders.order_status WITH ROLLUP;



-- Rejected orders based on brands and categories
SELECT brands.brand_name,
	   categories.category_name,
       COUNT(*) AS item_number_of_rejections,
       COUNT(DISTINCT orders.order_id) AS number_of_orders_with_rejected_item,
       GROUP_CONCAT(orders.order_id SEPARATOR ', ') AS rejected_order_ids
FROM orders
LEFT JOIN order_items
	ON orders.order_id = order_items.order_id
LEFT JOIN products
	ON order_items.product_id = products.product_id
LEFT JOIN brands
	ON products.brand_id = brands.brand_id
LEFT JOIN categories
	ON products.category_id = categories.category_id
WHERE orders.order_status = 3
GROUP BY brands.brand_name, categories.category_name
ORDER BY item_number_of_rejections DESC;


-- Select orders grouping based on order year
SELECT EXTRACT(YEAR FROM order_date) AS order_year,
	   COUNT(*) AS number_of_orders
FROM orders
GROUP BY EXTRACT(YEAR FROM order_date);

-- Select orders grouping based on order year and month
SELECT EXTRACT(YEAR FROM order_date) AS order_year,
	   EXTRACT(MONTH FROM order_date) AS order_month,
       COUNT(*) AS number_of_orders
FROM orders
GROUP BY EXTRACT(YEAR_MONTH FROM order_date);

-- Select orders grouping based on order year and season
SELECT order_year,
	   season,
       SUM(number_of_orders) AS total_orders
FROM (
		SELECT EXTRACT(YEAR FROM order_date) AS order_year,
			   EXTRACT(MONTH FROM order_date) AS order_month,
			   CASE
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 5 THEN 'Spring'
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 6 AND 8 THEN 'Summer'
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 9 AND 11 THEN 'Autumn'
					ELSE 'Winter'
			   END AS season,
			   COUNT(*) AS number_of_orders
		FROM orders
		GROUP BY EXTRACT(YEAR_MONTH FROM order_date)
	 ) AS num_of_orders_by_date
GROUP BY order_year, season;



-- Late shipped orders grouped by store
SELECT COALESCE(stores.store_name, 'TOTAL') AS stores,
	   COUNT(*) AS number_of_late_shipped_orders
FROM orders
LEFT JOIN stores
	ON orders.store_id = stores.store_id
WHERE shipped_date IS NOT NULL AND shipped_date > required_date
GROUP BY stores.store_name WITH ROLLUP;


-- Average time between order date and shipment date for each store and all stores overall
SELECT stores.store_name,
	   CONCAT(AVG(DATEDIFF(shipped_date, order_date)), ' days') AS average_order_processing_time,
       (
		SELECT CONCAT(AVG(DATEDIFF(shipped_date, order_date)), ' days')
		FROM orders
        WHERE shipped_date IS NOT NULL
       ) AS overall_average_order_processing_time
FROM orders
LEFT JOIN stores
	ON orders.store_id = stores.store_id
WHERE shipped_date IS NOT NULL
GROUP BY stores.store_name;


-- Number of orders for each store
SELECT COALESCE(stores.store_name, 'Total') AS store_name,
	   COUNT(*) number_of_orders
FROM orders
LEFT JOIN stores
	ON orders.store_id = stores.store_id
GROUP BY stores.store_name WITH ROLLUP;


-- Revenue of each store based on year and season
SELECT COALESCE(stores.store_name, 'TOTAL') AS store_name,
	   COALESCE(EXTRACT(YEAR FROM order_date), 'ALL YEARS') AS year,
       COALESCE(season, 'ALL SEASONS') AS season,
       ROUND(SUM(revenues_by_order_items.revenue), 2) AS store_revenue
FROM (
	  SELECT orders.order_date,
			 orders.store_id,
			 CASE
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 5 THEN 'Spring'
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 6 AND 8 THEN 'Summer'
					WHEN EXTRACT(MONTH FROM order_date) BETWEEN 9 AND 11 THEN 'Autumn'
					ELSE 'Winter'
			 END AS season,
             (order_items.quantity * order_items.list_price * (1 - order_items.discount)) AS revenue
	  FROM orders
	  LEFT JOIN order_items
		  ON orders.order_id = order_items.order_id
	 ) AS revenues_by_order_items
LEFT JOIN stores
	ON revenues_by_order_items.store_id = stores.store_id
GROUP BY stores.store_name, EXTRACT(YEAR FROM order_date), season WITH ROLLUP;



-- Brand names in each store that has the maximum and minimum order quantity
WITH ordered_item_quantities_by_brand AS (
	SELECT stores.store_name,
		   brands.brand_name,
		   SUM(order_items.quantity) AS quantity_ordered,
		   MAX(SUM(order_items.quantity)) OVER (PARTITION BY stores.store_name) AS quantity_of_brand_ordered_max_from_store,
		   MIN(SUM(order_items.quantity)) OVER (PARTITION BY stores.store_name) AS quantity_of_brand_ordered_min_from_store
	FROM orders
	LEFT JOIN stores
		ON orders.store_id = stores.store_id
	LEFT JOIN order_items
		ON orders.order_id = order_items.order_id
	LEFT JOIN products
		ON order_items.product_id = products.product_id
	LEFT JOIN brands
		ON products.brand_id = brands.brand_id
	GROUP BY brands.brand_name, stores.store_name
)
SELECT store_name,
	   brand_name,
       quantity_ordered
FROM ordered_item_quantities_by_brand
WHERE quantity_ordered = quantity_of_brand_ordered_max_from_store
UNION
SELECT store_name,
	   brand_name,
       quantity_ordered
FROM ordered_item_quantities_by_brand
WHERE quantity_ordered = quantity_of_brand_ordered_min_from_store
ORDER BY store_name, quantity_ordered DESC;


-- Category names in each store that has the maximum and minimum order quantity
WITH ordered_item_quantities_by_category AS (
	SELECT stores.store_name,
		   categories.category_name,
           SUM(order_items.quantity) AS quantity_ordered,
           MAX(SUM(order_items.quantity)) OVER (PARTITION BY stores.store_name) AS quantity_of_category_ordered_max_from_store,
           MIN(SUM(order_items.quantity)) OVER (PARTITION BY stores.store_name) AS quantity_of_category_ordered_min_from_store
    FROM orders
    LEFT JOIN stores
		ON orders.store_id = stores.store_id
	LEFT JOIN order_items
		ON orders.order_id = order_items.order_id
	LEFT JOIN products
		ON order_items.product_id = products.product_id
	LEFT JOIN categories
		ON products.category_id = categories.category_id
	GROUP BY categories.category_name, stores.store_name
)
SELECT store_name,
	   category_name,
       quantity_ordered
FROM ordered_item_quantities_by_category
WHERE quantity_ordered = quantity_of_category_ordered_max_from_store
UNION
SELECT store_name,
	   category_name,
       quantity_ordered
FROM ordered_item_quantities_by_category
WHERE quantity_ordered = quantity_of_category_ordered_min_from_store
ORDER BY store_name, quantity_ordered DESC;



-- Stock numbers in each store based on brand
SELECT stores.store_name,
	   brands.brand_name,
       SUM(quantity) AS total_quantity
FROM stocks
LEFT JOIN stores
	ON stocks.store_id = stores.store_id
LEFT JOIN products
	ON stocks.product_id = products.product_id
LEFT JOIN brands
	ON products.brand_id = brands.brand_id
GROUP BY stores.store_name, brands.brand_name
ORDER BY stores.store_name, total_quantity DESC;


-- Stock numbers in each store based on category
SELECT stores.store_name,
	   categories.category_name,
       SUM(quantity) AS total_quantity
FROM stocks
LEFT JOIN stores
	ON stocks.store_id = stores.store_id
LEFT JOIN products
	ON stocks.product_id = products.product_id
LEFT JOIN categories
	ON products.category_id = categories.category_id
GROUP BY stores.store_name, categories.category_name
ORDER BY stores.store_name, total_quantity DESC;


-- Items that are finished in stocks
SELECT stores.store_name,
	   stocks.product_id,
	   products.product_name,
       brands.brand_name,
       categories.category_name,
       products.model_year,
       products.list_price
FROM stocks
LEFT JOIN stores
	ON stocks.store_id = stores.store_id
LEFT JOIN products
	ON stocks.product_id = products.product_id
LEFT JOIN brands
	ON products.brand_id = brands.brand_id
LEFT JOIN categories
	ON products.category_id = categories.category_id
WHERE stocks.quantity = 0
ORDER BY store_name;



-- 	Quantity of items in each order
SELECT order_id,
	   total_item_quantity,
       AVG(total_item_quantity) OVER () AS average_item_quantity_in_orders
FROM (
	  SELECT order_id, SUM(quantity) AS total_item_quantity
	  FROM order_items
	  GROUP BY order_id
	  ORDER BY total_item_quantity DESC
	 ) AS item_quantities_in_orders;


-- Number of orders based on item quantities
SELECT total_item_quantity, COUNT(*) AS number_of_orders, GROUP_CONCAT(order_id) AS order_ids
FROM (
	  SELECT order_id, SUM(quantity) AS total_item_quantity
	  FROM order_items
	  GROUP BY order_id
	  ORDER BY total_item_quantity DESC
	 ) AS item_quantities_in_orders
GROUP BY total_item_quantity
ORDER BY total_item_quantity DESC;



-- Information of customers that have the most items in their orders
WITH item_quantities_in_orders AS (
	  SELECT order_id, SUM(quantity) AS total_item_quantity
	  FROM order_items
	  GROUP BY order_id
	  ORDER BY total_item_quantity DESC
)
SELECT orders.order_id,
	   item_quantities_in_orders.total_item_quantity,
	   customers.*
FROM customers
LEFT JOIN orders
	ON customers.customer_id = orders.customer_id
LEFT JOIN item_quantities_in_orders
	ON orders.order_id = item_quantities_in_orders.order_id
WHERE orders.order_id IN (
						  SELECT order_id
						  FROM item_quantities_in_orders
						  WHERE total_item_quantity = (
													   SELECT MAX(total_item_quantity)
													   FROM item_quantities_in_orders
													  )
						  ORDER BY total_item_quantity DESC
						 );
                         

-- Number of items ordered based on brand
SELECT COALESCE(brands.brand_name, 'ALL') AS brand_name,
	   SUM(quantity) AS total_items_ordered,
       ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)), 2) AS brand_revenue
FROM order_items
LEFT JOIN products
	ON order_items.product_id = products.product_id
LEFT JOIN brands
	ON products.brand_id = brands.brand_id
GROUP BY brands.brand_name WITH ROLLUP
ORDER BY total_items_ordered;


-- Number of items ordered based on category
SELECT COALESCE(categories.category_name, 'ALL') AS category_name,
	   SUM(order_items.quantity) AS total_items_ordered,
       ROUND(SUM(order_items.list_price * order_items.quantity * (1 - order_items.discount)), 2) AS category_revenue
FROM order_items
LEFT JOIN products
	ON order_items.product_id = products.product_id
LEFT JOIN categories
	ON products.category_id = categories.category_id
GROUP BY categories.category_name WITH ROLLUP
ORDER BY total_items_ordered;
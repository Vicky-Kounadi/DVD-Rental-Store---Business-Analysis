USE sakila;
SELECT * FROM film LIMIT 10;
SELECT * FROM inventory LIMIT 10;
SELECT * FROM customer LIMIT 10;
SELECT * FROM film_category LIMIT 10;
SELECT * FROM payment LIMIT 10;
SELECT * FROM rental LIMIT 10;
SELECT * FROM staff LIMIT 10;
SELECT * FROM store LIMIT 10;

-- FILMS
-- Top 10 most rented films
SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC
LIMIT 10;

-- CATEGORIES
-- Top most rented categories
SELECT c.category_id, c.name, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY rental_count DESC;


-- CUSTOMERS
-- Top 10 customer, based on num of rentals
-- SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS rental_count
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY rental_count DESC
LIMIT 10;

-- Top 10 customer, based on revenue they bring
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) as total_revenue
FROM payment p
JOIN customer c ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC
LIMIT 10;


-- Customers based on revenue + rentals
WITH 
top_rental AS(
	SELECT c.customer_id, COUNT(r.rental_id) AS rental_count
	FROM rental r
	JOIN customer c ON r.customer_id = c.customer_id
	GROUP BY c.customer_id
),
top_revenue AS(
	SELECT c.customer_id,SUM(p.amount) as total_revenue
	FROM payment p
	JOIN customer c ON c.customer_id = p.customer_id
	GROUP BY c.customer_id
)

SELECT trent.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
		trent.rental_count AS rental_count, 
        ROUND(trev.total_revenue, 2) AS total_revenue,
		CASE 
		  WHEN rental_count >= 30 OR total_revenue >= 150
		  THEN 'High Value'
		  WHEN (rental_count >= 20 AND rental_count < 30) OR (total_revenue >= 80 AND total_revenue < 150)
		  THEN 'Medium Value'
		  ELSE 'Low Value'
		END AS value_tier
FROM top_rental trent
JOIN top_revenue trev ON trev.customer_id = trent.customer_id
JOIN customer c ON c.customer_id = trent.customer_id
ORDER BY trent.rental_count DESC, trev.total_revenue DESC;


-- LATE RETURNS
WITH lateness AS (
	SELECT r.rental_id, r.customer_id, r.rental_date, r.return_date, f.film_id, f.rental_duration, 
			DATE_ADD(r.rental_date, INTERVAL f.rental_duration DAY) AS exp_return_date
	FROM rental r
	JOIN inventory i ON  r.inventory_id = i.inventory_id
	JOIN film f ON i.film_id = f.film_id
	),
total_late AS(
	SELECT *,  
			CASE 
			  WHEN l.return_date IS NULL
			  THEN 'Not Returned'
			  WHEN l.return_date > l.exp_return_date
			  THEN 'Late'
			  WHEN l.return_date <= l.exp_return_date
			  THEN 'On Time'
			  ELSE 'Not Returned'
			END AS return_status,
			CASE 
			  WHEN l.return_date > l.exp_return_date
			  THEN DATEDIFF(l.return_date, l.exp_return_date)
			  ELSE 0
			END AS late_days,
			CASE 
			  WHEN l.return_date > l.exp_return_date
			  THEN DATEDIFF(l.return_date, l.exp_return_date) * 0.50 -- cant use the as late_days yet
			  ELSE 0
			END AS late_fee
	FROM lateness l
    )
SELECT tl.customer_id, c.first_name, c.last_name,
	COUNT(tl.rental_id) AS total_rentals, 
	SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END) AS late_instances,
    SUM(late_fee) AS total_late_fee,
    ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) AS late_rate
FROM total_late tl
JOIN customer c ON c.customer_id = tl.customer_id
GROUP BY tl.customer_id, c.first_name, c.last_name
ORDER BY tl.customer_id;



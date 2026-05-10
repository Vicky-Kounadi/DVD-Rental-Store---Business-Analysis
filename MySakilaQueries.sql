USE sakila;
SELECT * FROM film LIMIT 10;
SELECT * FROM inventory LIMIT 10;
SELECT * FROM customer LIMIT 10;
SELECT * FROM film_category LIMIT 10;
SELECT * FROM payment LIMIT 10;
SELECT * FROM rental LIMIT 10;
SELECT * FROM staff LIMIT 10;
SELECT * FROM store LIMIT 10;

-- DATA VALIDATION
-- Check if null values
SELECT 
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN rental_date IS NULL THEN 1 ELSE 0 END) AS null_rental_date,
    SUM(CASE WHEN inventory_id IS NULL THEN 1 ELSE 0 END) AS null_inventory_id
FROM rental;

-- Duplicate rent records
SELECT rental_id, COUNT(*) AS duplicate_count
FROM rental
GROUP BY rental_id
HAVING COUNT(*) > 1;

-- Valid payments
SELECT *
FROM payment
WHERE amount < 0;

-- Unpaid rentals
SELECT r.rental_id
FROM rental r
LEFT JOIN payment p ON r.rental_id = p.rental_id
WHERE p.payment_id IS NULL;

-- Invalid rent dates
SELECT rental_id, rental_date, return_date
FROM rental
WHERE return_date < rental_date;

-- Invalid inventory slot, film doesnt exist
SELECT i.inventory_id
FROM inventory i
LEFT JOIN film f ON i.film_id = f.film_id
WHERE f.film_id IS NULL;

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
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, SUM(p.amount) as total_revenue
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
SELECT tl.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	COUNT(tl.rental_id) AS total_rentals, 
	SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END) AS late_instances,
    SUM(late_fee) AS total_late_fee,
    ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) AS late_rate,
        CASE 
		  WHEN ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) >= 0.6
		  THEN 'Risky'
		  WHEN ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) <= 0.3
		  THEN 'Reliable'
		  ELSE 'Neutral'
		END AS risk_tier
FROM total_late tl
JOIN customer c ON c.customer_id = tl.customer_id
GROUP BY tl.customer_id, c.first_name, c.last_name
ORDER BY tl.customer_id;

-- Customers based on revenue + rentals + reliability
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
),
value_layer AS (
    SELECT 
        trent.customer_id,
        trent.rental_count,
        ROUND(trev.total_revenue, 2) AS total_revenue,
        CASE 
            WHEN trent.rental_count >= 30 OR trev.total_revenue >= 150 THEN 'High Value'
            WHEN (trent.rental_count >= 20 AND trent.rental_count < 30) 
              OR (trev.total_revenue >= 80 AND trev.total_revenue < 150) THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_tier
    FROM top_rental trent
	JOIN top_revenue trev ON trev.customer_id = trent.customer_id
),
lateness AS (
    SELECT 
        r.rental_id, 
        r.customer_id, 
        r.rental_date, 
        r.return_date, 
        f.rental_duration,
        DATE_ADD(r.rental_date, INTERVAL f.rental_duration DAY) AS exp_return_date
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
),
total_late AS (
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
),
risk_layer AS (
   SELECT tl.customer_id,
		COUNT(tl.rental_id) AS total_rentals, 
		SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END) AS late_instances,
		SUM(late_fee) AS total_late_fee,
		ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) AS late_rate,
		CASE 
			  WHEN ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) >= 0.6
			  THEN 'Risky'
			  WHEN ROUND (SUM(CASE WHEN late_days > 0 THEN 1 ELSE 0 END)/COUNT(tl.rental_id), 2) <= 0.3
			  THEN 'Reliable'
			  ELSE 'Neutral'
			END AS risk_tier
	FROM total_late tl
	GROUP BY tl.customer_id
)
SELECT 
    c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    vl.rental_count, vl.total_revenue, vl.value_tier,
    rl.total_rentals, rl.late_instances, rl.total_late_fee, rl.late_rate, rl.risk_tier
FROM value_layer vl
JOIN risk_layer rl ON vl.customer_id = rl.customer_id
JOIN customer c ON c.customer_id = vl.customer_id
ORDER BY vl.total_revenue DESC;

-- RENTAL TRENDS OVER TIME
-- Rents + revenue per month
SELECT MONTHNAME(r.rental_date) AS month_name,
	COUNT(r.rental_id) AS rentals_per_month, 
	ROUND(SUM(p.amount),2) AS revenue_per_month
FROM rental r
JOIN payment p ON r.rental_id=p.rental_id
GROUP BY month_name
ORDER BY rentals_per_month DESC;

-- Rents + revenue per day
SELECT DAYNAME(r.rental_date) AS day_name,
	COUNT(r.rental_id) AS rentals_per_day, 
	ROUND(SUM(p.amount),2) AS revenue_per_day
FROM rental r
JOIN payment p ON r.rental_id=p.rental_id
GROUP BY day_name
-- ORDER BY rentals_per_day DESC;
ORDER BY FIELD(day_name, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- REVENUE PER CATEGORY
WITH 
rental_category AS(
	SELECT c.category_id, c.name, r.rental_id
	FROM rental r
	JOIN inventory i ON r.inventory_id = i.inventory_id
	JOIN film f ON i.film_id = f.film_id
	JOIN film_category fc ON f.film_id = fc.film_id
	JOIN category c ON fc.category_id = c.category_id
),
payment_per_rental AS(
	SELECT r.rental_id, p.payment_id, p.amount
	FROM rental r
	JOIN payment p ON r.rental_id=p.rental_id
)
SELECT rc.category_id, rc.name, 
	ROUND(SUM(ppr.amount), 2) AS revenue_per_category,
    COUNT(rc.rental_id) AS rental_count,
    ROUND(SUM(ppr.amount) / COUNT(rc.rental_id), 2) AS average_revenue_per_rental
FROM rental_category rc
JOIN payment_per_rental ppr ON rc.rental_id = ppr.rental_id
GROUP BY rc.category_id
ORDER BY revenue_per_category DESC;

-- STAFF PROFITABILITY
SELECT r.staff_id, CONCAT(s.first_name, ' ', s.last_name) AS staff_name, s.store_id,
	COUNT(r.rental_id) AS total_transactions, 
    ROUND(SUM(p.amount),2) AS total_revenue,
    ROUND(SUM(p.amount) / COUNT(r.rental_id), 2) AS efficiency
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY r.staff_id, s.first_name, s.last_name, s.store_id;

-- STORE PROFITABILITY
-- Rentals per store
SELECT s.store_id, COUNT(r.rental_id) AS rent_store
FROM rental r
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY s.store_id;

-- Revenue per store
SELECT s.store_id, ROUND(SUM(p.amount), 2) AS rev_store
FROM rental r
JOIN staff s ON r.staff_id = s.staff_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY s.store_id;

-- Total store performance
WITH 
rent_per_store AS(
	SELECT s.store_id, COUNT(r.rental_id) AS rent_store
	FROM rental r
	JOIN staff s ON r.staff_id = s.staff_id
	GROUP BY s.store_id
),
rev_per_store AS(
	SELECT s.store_id, ROUND(SUM(p.amount), 2) AS rev_store
	FROM rental r
	JOIN staff s ON r.staff_id = s.staff_id
	JOIN payment p ON r.rental_id = p.rental_id
	GROUP BY s.store_id
),
store_staff AS(
	SELECT r.staff_id, s.first_name, s.last_name, CONCAT(s.first_name, ' ', s.last_name) AS staff_name, s.store_id,
		ROUND(SUM(p.amount),2) AS total_revenue
	FROM rental r
	JOIN payment p ON r.rental_id = p.rental_id
	JOIN staff s ON r.staff_id = s.staff_id
    GROUP BY s.store_id, s.staff_id
),
total_company AS (
	SELECT SUM(p.amount) AS total_company_revenue
	FROM payment p
)
SELECT rentps.store_id, 
	rentps.rent_store, revps.rev_store,
     ROUND(revps.rev_store / rentps.rent_store, 2) AS avg_revenue_per_rental,
     ss.staff_name, ss.total_revenue AS staff_revenue,
     ROUND((ss.total_revenue / tc.total_company_revenue) * 100, 2) AS staff_contribution_to_company_pct
FROM rent_per_store rentps
JOIN rev_per_store revps ON rentps.store_id = revps.store_id
JOIN store_staff ss ON rentps.store_id = ss.store_id
CROSS JOIN total_company tc;


-- VIEWS FOR VISUALIZATIONS

-- Brief stats
CREATE VIEW v_data_summary AS
SELECT
  (SELECT SUM(amount) FROM payment) AS total_revenue,
  (SELECT COUNT(*) FROM rental) AS total_rentals,
  (SELECT COUNT(DISTINCT customer_id) FROM customer) AS total_customers
;

select * from v_data_summary;


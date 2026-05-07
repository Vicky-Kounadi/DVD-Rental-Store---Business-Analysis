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



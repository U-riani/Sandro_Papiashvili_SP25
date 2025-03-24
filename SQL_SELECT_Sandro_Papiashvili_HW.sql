-- All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
 -- try-1
SELECT f.title
FROM film f
INNER JOIN 
	(SELECT * 
	FROM film_category fc
	WHERE fc.category_id = (
		SELECT c.category_id
		FROM category c
		WHERE c.name = 'Animation'
		))  animation_movies
ON f.film_id = animation_movies.film_id
WHERE f.release_year  BETWEEN 2017 AND 2019 
AND f.rental_rate > 1
ORDER BY f.title;

-- try-2 with cte
WITH animation_movies AS (
	SELECT * 
	FROM film_category fc
	WHERE fc.category_id = (
		SELECT c.category_id
		FROM category c
		WHERE c.name = 'Animation'
		)
	)
SELECT f.title
FROM film f
INNER JOIN animation_movies
ON f.film_id = animation_movies.film_id
WHERE f.release_year  BETWEEN 2017 AND 2019 
AND f.rental_rate > 1
ORDER BY f.title;



-- The revenue earned by each rental store after March 2017 
-- (columns: address and address2 – as one column, revenue)
SELECT a.address || ',' || COALESCE(a.address2, '') AS full_address, 
		SUM(p.amount) AS rvenue
FROM inventory i
INNER JOIN rental r
ON i.inventory_id  = r.inventory_id
INNER JOIN payment p
ON r.rental_id = p.rental_id
INNER JOIN store s
ON i.store_id = s.store_id
INNER JOIN address a 
ON s.address_id = a.address_id
WHERE p.payment_date >='2017-04-01 00:00:00'
GROUP BY s.store_id, full_address;




/*Top-5 actors by number of movies (released after 2015) they 
took part in (columns: first_name, last_name, number_of_movies, 
sorted by number_of_movies in descending order)*/
SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
FROM film f
INNER JOIN film_actor fa 
ON f.film_id = fa.film_id
INNER JOIN actor a
ON fa.actor_id = a.actor_id
WHERE f.release_year > 2015
GROUP BY a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;




/*Number of Drama, Travel, Documentary per year 
(columns: release_year, number_of_drama_movies, 
number_of_travel_movies, number_of_documentary_movies), 
sorted by release year in descending order. Dealing with 
NULL values is encouraged)*/
SELECT f.release_year, 
		SUM(CASE WHEN UPPER(c.name) = 'DRAMA' THEN 1 ELSE 0 END) AS number_of_drama_movies,
		SUM(CASE WHEN UPPER(c.name) = 'TRAVEL'THEN 1 ELSE 0 END) AS number_of_travel_movies,
		SUM(CASE WHEN UPPER(c.name) = 'DOCUMENTARY'THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM film_category fc
INNER JOIN category c 
ON fc.category_id  = c.category_id
INNER JOIN film f 
ON fc.film_id = f.film_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;


-- part2 -- task-1
/*Which three employees generated the most revenue in 2017? 
They should be awarded a bonus for their outstanding 
performance. */
SELECT
    st.first_name,
    st.last_name,
    s.store_id,
    SUM(p.amount) AS total_revenue
FROM
    payment p
JOIN staff st 
	ON p.staff_id = st.staff_id
JOIN store s 
	ON s.store_id = st.store_id
WHERE
    EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY
    st.staff_id, s.store_id, st.first_name, st.last_name
ORDER BY
    total_revenue DESC
LIMIT 3;



-- part2 -- task-2
/*2. Which 5 movies were rented more than others 
(number of rentals), and what's the expected age of 
the audience for these movies? To determine expected age 
please use 'Motion Picture Association film rating system*/
SELECT f.title, f.rating, COUNT(f.film_id) AS top_rented_films
FROM rental r
INNER JOIN inventory i 
ON r.inventory_id  = i.inventory_id
INNER JOIN film f
ON i.film_id  = f.film_id
GROUP BY f.title, f.rating 
ORDER BY top_rented_films DESC
LIMIT 5;


-- tpart-3 -- task-1
/*Part 3. Which actors/actresses didn't act for a longer
 period of time than the others? 
 V1: gap between the latest release_year and current year 
 per each actor;*/
-- try-1
SELECT a.first_name, a.last_name,
	(EXTRACT(year FROM current_date) - MAX(f.release_year)
	) AS act_before
FROM film_actor fa 
INNER JOIN film f 
ON fa.film_id = f.film_id
INNER JOIN actor a 
ON fa.actor_id  = a.actor_id 
GROUP BY a.first_name, a.last_name
ORDER BY act_before DESC;


-- with cte
WITH actor_last_act AS (
	SELECT fa.actor_id, 
	(EXTRACT(year FROM current_date) - MAX(f.release_year)) AS act_before
	FROM film_actor fa 
	inner JOIN film f 
	ON fa.film_id = f.film_id
	GROUP BY fa.actor_id
	) 
SELECT a.first_name, a.last_name, la.act_before
FROM actor a 
INNER JOIN actor_last_act la
ON a.actor_id = la.actor_id 
ORDER BY la.act_before DESC;


-- tpart-3 -- task-1
-- V2: gaps between sequential films per each actor;
WITH movies AS (
	SELECT fa.actor_id , f.release_year
	FROM film_actor fa 
	INNER JOIN film f 
	ON fa.film_id = f.film_id
	ORDER BY actor_id, f.release_year
)
SELECT a.first_name, a.last_name, 
		MAX(t2.release_year - t1.release_year) AS max_sequential_gap
FROM movies t1
JOIN movies t2 
    ON t1.actor_id = t2.actor_id 
    AND t2.release_year = (
        SELECT MIN(t3.release_year)
        FROM movies t3
        WHERE t3.actor_id = t1.actor_id 
        AND t3.release_year > t1.release_year
    )
INNER JOIN actor a 
ON t1.actor_id = a.actor_id
GROUP BY a.first_name, a.last_name
ORDER BY max_sequential_gap DESC;












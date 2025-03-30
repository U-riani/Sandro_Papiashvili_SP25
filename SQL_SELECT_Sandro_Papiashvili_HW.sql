-- All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
-- We filter by 'Animation' category and release year, ensuring rental rate is greater than 1
WITH animation_movies AS (
WITH animation_movies AS (
    SELECT fc.film_id
    FROM public.film_category fc
    INNER JOIN public.category c ON fc.category_id = c.category_id
    WHERE UPPER(c.name) = 'ANIMATION'
)
SELECT f.title
FROM public.film f
INNER JOIN animation_movies am ON f.film_id = am.film_id
WHERE f.release_year BETWEEN 2017 AND 2019 
    AND f.rental_rate > 1
ORDER BY f.title;


-- The revenue earned by each rental store after March 2017 
-- (columns: address and address2 – as one column, revenue)
-- We sum payments for rentals after the specified date, grouping by store location
SELECT a.address || ', ' || COALESCE(a.address2, '') AS full_address, 
       SUM(p.amount) AS revenue
FROM public.inventory i
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
INNER JOIN public.payment p ON r.rental_id = p.rental_id
INNER JOIN public.store s ON i.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date >= '2017-04-01 00:00:00'
GROUP BY s.store_id, full_address;




/*Top-5 actors by number of movies (released after 2015) they 
took part in (columns: first_name, last_name, number_of_movies, 
sorted by number_of_movies in descending order)*/
-- We count films for each actor released after 2015, ensuring uniqueness via actor_id
SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
FROM public.film_actor fa
INNER JOIN public.film f ON fa.film_id = f.film_id
INNER JOIN public.actor a ON fa.actor_id = a.actor_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;




/*Number of Drama, Travel, Documentary per year 
(columns: release_year, number_of_drama_movies, 
number_of_travel_movies, number_of_documentary_movies), 
sorted by release year in descending order. Dealing with 
NULL values is encouraged)*/
-- We count movies by category per release year, ensuring proper categorization
SELECT f.release_year, 
       SUM(CASE WHEN UPPER(c.name) = 'DRAMA' THEN 1 ELSE 0 END) AS number_of_drama_movies,
       SUM(CASE WHEN UPPER(c.name) = 'TRAVEL' THEN 1 ELSE 0 END) AS number_of_travel_movies,
       SUM(CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM public.film_category fc
INNER JOIN public.category c ON fc.category_id = c.category_id
INNER JOIN public.film f ON fc.film_id = f.film_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;


-- part2 -- task-1
/*Which three employees generated the most revenue in 2017? 
They should be awarded a bonus for their outstanding 
performance. */
-- We sum revenue per employee, uniquely identified by staff_id
SELECT st.staff_id, st.first_name, st.last_name, s.store_id, SUM(p.amount) AS total_revenue
FROM public.payment p
INNER JOIN public.staff st ON p.staff_id = st.staff_id
INNER JOIN public.store s ON st.store_id = s.store_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY st.staff_id, s.store_id
ORDER BY total_revenue DESC
LIMIT 3;



-- part2 -- task-2
/*2. Which 5 movies were rented more than others 
(number of rentals), and what's the expected age of 
the audience for these movies? To determine expected age 
please use 'Motion Picture Association film rating system*/
-- We count rentals per movie and map rating abbreviations to audience descriptions
SELECT f.film_id, f.title, 
       CASE 
           WHEN f.rating = 'G' THEN 'All ages'
           WHEN f.rating = 'PG' THEN 'Parental guidance suggested (10+)'
           WHEN f.rating = 'PG-13' THEN 'Parents strongly cautioned (13+)'
           WHEN f.rating = 'R' THEN 'Restricted (17+)'
           WHEN f.rating = 'NC-17' THEN 'Adults only (18+)' 
       END AS expected_audience,
       COUNT(r.rental_id) AS rental_count
FROM public.rental r
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;


-- tpart-3 -- task-1
/*Part 3. Which actors/actresses didn't act for a longer
 period of time than the others? 
 V1: gap between the latest release_year and current year 
 per each actor;*/
-- We find the last movie year per actor and calculate the gap from the current year
WITH actor_last_act AS (
    SELECT fa.actor_id, MAX(f.release_year) AS last_movie_year
    FROM public.film_actor fa
    INNER JOIN public.film f ON fa.film_id = f.film_id
    GROUP BY fa.actor_id
)
SELECT a.actor_id, a.first_name, a.last_name,
       EXTRACT(YEAR FROM current_date) - ala.last_movie_year AS years_since_last_movie
FROM public.actor a
INNER JOIN actor_last_act ala ON a.actor_id = ala.actor_id
ORDER BY years_since_last_movie DESC;

-- part-3 -- task-1
-- V2: gaps between sequential films per each actor;
-- We compare sequential movie years per actor and find the maximum gap
WITH movies AS (
    SELECT fa.actor_id, f.release_year
    FROM public.film_actor fa
    INNER JOIN public.film f ON fa.film_id = f.film_id
)
SELECT a.actor_id, a.first_name, a.last_name, 
       MAX(t2.release_year - t1.release_year) AS max_sequential_gap
FROM movies t1
INNER JOIN movies t2 ON t1.actor_id = t2.actor_id 
                     AND t2.release_year = (
                         SELECT MIN(t3.release_year)
                         FROM movies t3
                         WHERE t3.actor_id = t1.actor_id 
                         AND t3.release_year > t1.release_year
                     )
INNER JOIN public.actor a ON t1.actor_id = a.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY max_sequential_gap DESC;












-- 1. Insert Favorite Movies into 'film' Table
INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, rating, replacement_cost, last_update)
SELECT title, description, release_year, language_id, rental_duration, rental_rate, length, rating::mpaa_rating, replacement_cost, CURRENT_DATE
FROM (
    SELECT 
        'Avatar' AS title, 
        'A paraplegic marine explores Pandora.' AS description, 
        2009 AS release_year, 
        (SELECT language_id FROM public.language WHERE name = 'English' LIMIT 1) AS language_id, 
        7 AS rental_duration, 
        4.99 AS rental_rate, 
        162 AS length, 
        'PG-13' AS rating, 
        19.99 AS replacement_cost
    UNION ALL
    SELECT 
        'Interstellar', 
        'Explorers travel through a wormhole in space.', 
        2014, 
        (SELECT language_id FROM public.language WHERE name = 'English' LIMIT 1), 
        14, 
        9.99, 
        169, 
        'PG-13', 
        24.99
    UNION ALL
    SELECT 
        'Blade Runner', 
        'A blade runner hunts down rogue replicants.', 
        1982, 
        (SELECT language_id FROM public.language WHERE name = 'English' LIMIT 1), 
        21, 
        19.99, 
        117, 
        'R', 
        29.99
) AS new_movies
WHERE NOT EXISTS (
    SELECT 1 FROM public.film WHERE film.title = new_movies.title
)
RETURNING film_id;


-- 2. Insert Actors and Link to Films

INSERT INTO public.actor (first_name, last_name, last_update)
SELECT first_name, last_name, CURRENT_DATE
FROM (
	VALUES
	('Sam', 'Worthington'),
	('Zoe', 'Saldana'),
	('Matthew', 'McConaughey'),
	('Anne', 'Hathaway'),
    ('Ryan', 'Gosling'),
    ('Harrison', 'Ford')
    ) AS new_actors (first_name, last_name)
WHERE NOT EXISTS (
	SELECT 1 FROM public.actor WHERE actor.first_name = new_actors.first_name AND actor.last_name = new_actors.last_name
    ) 
RETURNING actor_id, first_name, last_name;



INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
	(SELECT actor_id FROM public.actor WHERE first_name = 'Sam' AND last_name = 'Worthington'),
    (SELECT film_id FROM public.film WHERE title = 'Avatar'),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM public.film_actor 
    WHERE actor_id = (SELECT actor_id FROM public.actor WHERE first_name = 'Sam' AND last_name = 'Worthington')
    AND film_id = (SELECT film_id FROM public.film WHERE title = 'Avatar')
);

INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT 
	(SELECT actor_id FROM public.actor WHERE first_name = 'Sam' AND last_name = 'Worthington'),
    (SELECT film_id FROM public.film WHERE title = 'Avatar'),
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM public.film_actor 
    WHERE actor_id = (SELECT actor_id FROM public.actor WHERE first_name = 'Sam' AND last_name = 'Worthington')
    AND film_id = (SELECT film_id FROM public.film WHERE title = 'Avatar')
);

WITH film_actor_mapping AS (
    SELECT 
        a.actor_id, 
        f.film_id, 
        CURRENT_DATE AS last_update
    FROM public.actor a
    JOIN public.film f 
        ON (a.first_name, a.last_name) IN (
            ('Sam', 'Worthington'),  -- Avatar
            ('Zoe', 'Saldana')       -- Avatar
        ) AND f.title = 'Avatar'   
    UNION ALL    
    SELECT 
        a.actor_id, 
        f.film_id, 
        CURRENT_DATE
    FROM public.actor a
    JOIN public.film f 
        ON (a.first_name, a.last_name) IN (
            ('Matthew', 'McConaughey'), -- Interstellar
            ('Anne', 'Hathaway')        -- Interstellar
        ) AND f.title = 'Interstellar'   
    UNION ALL
    SELECT 
        a.actor_id, 
        f.film_id, 
        CURRENT_DATE
    FROM public.actor a
    JOIN public.film f 
        ON (a.first_name, a.last_name) IN (
            ('Harrison', 'Ford'), -- Blade Runner 2049
            ('Ryan', 'Gosling')   -- Blade Runner 2049
        ) AND f.title = 'Blade Runner 2049'
)
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT fam.actor_id, fam.film_id, fam.last_update
FROM film_actor_mapping fam
WHERE NOT EXISTS (  -- ✅ Prevent duplicates
    SELECT 1 FROM public.film_actor fa
    WHERE fa.actor_id = fam.actor_id
    AND fa.film_id = fam.film_id
);

-- 3. Add Movies to Store Inventory
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, (SELECT store_id FROM public.store LIMIT 1), CURRENT_DATE
FROM public.film f
WHERE f.title IN ('Avatar', 'Interstellar', 'Blade Runner 2049')
AND NOT EXISTS (
    SELECT 1 FROM public.inventory WHERE inventory.film_id = f.film_id AND inventory.store_id = (SELECT store_id FROM public.store LIMIT 1)
)
RETURNING inventory_id;



-- 4. Update Existing Customer to Your Info
UPDATE public.customer
SET first_name = 'Sandro', last_name = 'Papiashvili', email = 'sandropapiashvili@gmail.com', last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT customer_id FROM public.customer
    WHERE (SELECT COUNT(*) FROM public.rental WHERE rental.customer_id = customer.customer_id) >= 43
    AND (SELECT COUNT(*) FROM public.payment WHERE payment.customer_id = customer.customer_id) >= 43
    ORDER BY last_update DESC
    LIMIT 1
)
RETURNING customer_id;



-- 5. Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
DELETE FROM public.payment
WHERE customer_id = (SELECT customer_id FROM public.customer WHERE first_name = 'Sandro' AND last_name = 'Papiashvili');

DELETE FROM public.rental
WHERE customer_id = (SELECT customer_id FROM public.customer WHERE first_name = 'Sandro' AND last_name = 'Papiashvili');


-- 6. Rent Movies and Make Payments
WITH inserted_rental AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
    SELECT 
        CURRENT_DATE, 
        i.inventory_id,
        c.customer_id,
        s.staff_id,
        CURRENT_DATE
    FROM inventory i
    INNER JOIN film f ON i.film_id = f.film_id
    CROSS JOIN (
        SELECT customer_id 
        FROM customer 
        WHERE UPPER(first_name) = 'SANDRO' AND UPPER(last_name) = 'PAPIASHVILI'
        LIMIT 1
    ) c
    CROSS JOIN (
        SELECT staff_id 
        FROM staff 
        ORDER BY store_id
        LIMIT 1
    ) s
    WHERE UPPER(f.title) IN ('AVATAR', 'INTERSTELLAR', 'BLADE RUNNER 2049')
    RETURNING customer_id, staff_id, rental_id
)
insert into payment(customer_id, staff_id, rental_id, amount, payment_date)
select customer_id, staff_id, rental_id, 9.99, '2017-01-24 22:40:19.996 +0400'
from inserted_rental;



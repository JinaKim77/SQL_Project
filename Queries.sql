# Query 1 - query used for first insight

# We want to understand more about the movies that families are watching.
# The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music.

# Create a query that lists each movie, the film category it is classified in, and the number of times it has been rented out.

# One way to solve this is to create a count of movies using aggregations, subqueries and Window functions.

SELECT DISTINCT(film_title),
       catetory_name,
	   COUNT(rentaldate) OVER (PARTITION BY film_title) as rental_count
FROM
  (SELECT f.title film_title,
          c.name catetory_name,
          r.rental_date rentaldate
   FROM film f
   JOIN film_category fc
   ON f.film_id=fc.film_id
   JOIN category c
   ON c.category_id=fc.category_id
   JOIN inventory i
   ON i.film_id=f.film_id
   JOIN rental r
   ON i.inventory_id=r.inventory_id) t1
WHERE catetory_name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
ORDER BY 2,1;


# Query 2 - query used for second insight

# Now we need to know how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for.
# Can you provide a table with the movie titles and divide them into 4 levels (first_quarter, second_quarter, third_quarter, and final_quarter)
# based on the quartiles (25%, 50%, 75%) of the rental duration for movies across all categories?
# Make sure to also indicate the category that these family-friendly movies fall into.

# One way to solve it requires the use of percentiles, Window functions, subqueries or temporary tables.

SELECT f.title,
       c.name,
       f.rental_duration,
	   NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_qualtiles
FROM film f
JOIN film_category fc
ON fc.film_id = f.film_id
JOIN category c
ON c.category_id=fc.category_id
WHERE c.name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')


# Query 3 - query used for third insight

# Povide a table with the family-friendly film category, each of the quartiles, and the corresponding count of movies
# within each combination of film category for each corresponding rental duration category.
# The resulting table should have three columns:

SELECT categoryname,
       standard_qualtiles,
       COUNT(*)
FROM
  (SELECT f.title title,
          c.name categoryname,
          f.rental_duration,
	      NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_qualtiles
   FROM film f
   JOIN film_category fc
   ON fc.film_id = f.film_id
   JOIN category c
   ON c.category_id=fc.category_id
   WHERE c.name in ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))t1
GROUP BY 1,2
ORDER BY 1,2


# Query 4 - query used for fourth insight

# We want to find out how the two stores compare in their count of rental orders during every month for all the years we have data for.
# Write a query that returns the store ID for the store, the year and month and the number of rental orders each store has fulfilled for that month.
# Your table should include a column for each of the following: year, month, store ID and count of rental orders fulfilled during that month.

# The count of rental orders is sorted in descending order.

WITH dsf AS(
  SELECT r.rental_date rentaldate,
         date_part('year', r.rental_date) AS Rental_year,
         date_part('month', r.rental_date) AS Rental_month,
         s.store_id AS Store_ID
  FROM store s
  JOIN staff st
  ON st.store_id = s.store_id
  JOIN rental r
  ON r.staff_id = st.staff_id
)
SELECT Rental_month,
       Rental_year,
       Store_ID,
       COUNT(rentaldate) AS Count_rentals
FROM dsf
GROUP BY 1,2,3
ORDER  BY 4 DESC;


# Query 5

# We would like to know who were our top 10 paying customers,
# how many payments they made on a monthly basis during 2007,
# and what was the amount of the monthly payments.
# Can you write a query to capture the customer name, month and year of payment,
# and total payment amount for each month by these top 10 paying customers?

WITH top_10 AS (
  SELECT  c.first_name || ' ' || c.last_name AS full_name,
          date_trunc('year', p.payment_date) AS pay_year,
          SUM(p.amount) as payment_amount
  FROM customer c
  JOIN payment p
  ON c.customer_id=p.customer_id
  GROUP BY 1,2
  ORDER BY 3 DESC
  LIMIT 10
)
SELECT top.full_name,
       date_trunc('month', p.payment_date) AS pay_mon,
	   COUNT(*) AS pay_countpermon,
	   SUM(p.amount) as payment_amount
FROM customer c
JOIN payment p
ON c.customer_id=p.customer_id
JOIN top_10 top
ON c.first_name || ' ' || c.last_name=top.full_name
GROUP BY 1,2
ORDER BY 1


# Query 6

# Finally, for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007.
# write a query to compare the payment amounts in each successive month.
# Repeat this for each of these 10 paying customers.
# Identify the customer name who paid the most difference in terms of payments.

WITH top_10_2017 AS (
  SELECT  c.first_name || ' ' || c.last_name AS full_name,
          date_trunc('year', p.payment_date) AS pay_year,
          SUM(p.amount) as payment_amount
  FROM customer c
  JOIN payment p
  ON c.customer_id=p.customer_id
  GROUP BY 1,2
  ORDER BY 3 DESC
  LIMIT 10
),
top_10_monthly AS(
  SELECT *
  FROM
  (SELECT top.full_name AS fullname,
          date_trunc('month', p.payment_date) AS pay_mon,
	      COUNT(*) AS pay_countpermon,
	      SUM(p.amount) as payment_amount
  FROM customer c
  JOIN payment p
  ON c.customer_id=p.customer_id
  JOIN top_10_2017 top
  ON c.first_name || ' ' || c.last_name=top.full_name
  GROUP BY 1,2)t1
  ORDER BY 1
)
SELECT fullname,
       pay_mon,
       pay_countpermon,
	   lag AS amount_before,
       payment_amount amount_present,
       difference
FROM
(SELECT fullname,
	    date_part('month',pay_mon) as pay_mon,
	    pay_countpermon,
	    payment_amount,
	    LAG(payment_amount) OVER (PARTITION BY fullname) AS lag,
	    LEAD(payment_amount) OVER (PARTITION BY fullname) AS lead,
	    payment_amount-(LAG(payment_amount) OVER (PARTITION BY fullname)) AS difference
FROM top_10_monthly)t1
WHERE difference IS NOT NULL
ORDER BY difference DESC

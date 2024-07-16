-- View to verify the tables have been loaded to the DB
SELECT *
FROM company_dim;

SELECT *
FROM job_postings_fact
LIMIT 100; -- or could kill my pc

SELECT *
FROM skills_dim;

SELECT *
FROM skills_job_dim;

-- HANDLING DATE AND TIME
SELECT job_posted_date
FROM job_postings_fact
LIMIT 10;

/*
    - ::DATE > Converts to a date format by removing the time portion
    - AT TIME ZONE > Converts a timestamp to a specified time zone
    - EXTRACT > Gets specified date parts (year, month, day)
*/

-- ::DATE at work
SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date::DATE AS date
FROM
    job_postings_fact;

-- AT TIME ZONE at work
SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EAT' AS date
FROM
    job_postings_fact
LIMIT 10;

-- EXTRACT at work, used as a function within the select satement
SELECT
    EXTRACT(DAY FROM job_posted_date) AS day,
    EXTRACT(MONTH FROM job_posted_date) AS month,
    EXTRACT(YEAR FROM job_posted_date) AS year
FROM
    job_postings_fact
LIMIT 10;

-- CREATE TABLES FROM A TABLE
-- Job postings for the months of january, february and march
-- JANUARY
CREATE TABLE january_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;

-- FEBRUARY
CREATE TABLE february_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 2;

-- MARCH
CREATE TABLE march_jobs AS
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 3;

-- do a preview, just to verify
SELECT *
FROM march_jobs
LIMIT 10;

/*
    - CASE EXPRESSION in Sequel
    - Remember case-when i R? This basically is it, in SQL
    - An example
    - Let's look at the job location,
    - It's either, in your town, say NYC, or anywhere i.e remote, or in another city, call it on site
*/
SELECT
    COUNT(job_id) AS num_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY location_category;

-- SUBQUERIES (for simpler queries) AND COMMON TABLE EXPRESSIONS(CTEs, for complex quesries)
-- Subqueries (can be used in SELECT, FROM, WHERE or HAVING clauses)
SELECT *
FROM( -- Subquery starts here
    SELECT *
    FROM job_postings_fact
    WHERE EXTRACT(MONTH FROM job_posted_date) = 1;
) AS january_jobs; -- Subquery ends here

-- deeper subquery example
SELECT
    company_id,
    name AS company_name
FROM
    company_dim
WHERE company_id IN(
    SELECT
        company_id
    FROM
        job_postings_fact
    WHERE
        job_no_degree_mention = true
    ORDER BY
        company_id
)


-- CTEs, generates temporary result set
WITH january_jobs AS( -- CTE definition
    SELECT *
    FROM job_postings_fact
    WHERE(EXTRACT MONTH FROM job_posted_date) = 1
)  -- CTE definition ends here

/*
    - Find companies that have the most job openings
    - Get the total number of job postings per company_id (job_postings_fact)
    - Return the total number of jobs with the company name (company_dim)
*/
SELECT
    company_id,
    COUNT(*) -- do an aggregation
FROM
    job_postings_fact
GROUP BY -- when doing an aggregation you need to perform a grouping
    company_id

-- now write a CTE to swallow the above
WITH company_job_counts AS(
    SELECT
    company_id,
    COUNT(*) AS total_jobs
FROM
    job_postings_fact
GROUP BY
    company_id
)

SELECT 
    company_dim.name AS company_name,
    company_job_counts.total_jobs
FROM company_dim
LEFT JOIN company_job_counts ON company_job_counts.company_id = company_dim.company_id
ORDER BY 
    total_jobs DESC

/*
Find the count of number of remote jobs per skill
    - Display the top 5 skills by their demand in remote jobs
    - Include skill ID, name, and count of postings requiring the skill
*/
SELECT
    COUNT(*),
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact
GROUP BY
    location_category

--------------------------
---------------------------
--------------------------
-- UNION
/*
Combines results from two or more SELECT statements
    - must have equal no. of columns, of matching datatypes
    - gets rid of duplicate rows i.e rows are unique, unlike UNION ALL

*/
    -- Get January jobs
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    january_jobs

UNION -- union returns unique rows

    -- Get February jobs
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    february_jobs

UNION

    -- Get  March jobs
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    march_jobs


-- UNION ALL
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    january_jobs

UNION ALL -- union all returns even duplicate rows

    -- Get February jobs
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    february_jobs

UNION ALL

    -- Get  March jobs
SELECT
    job_title_short,
    company_id,
    job_location
FROM
    march_jobs

/*
Find job postings from the first quater that have a salary greater than $70K
    - Combine job postings tables from Q1-Q3 (Jan - March)
    - Get job postings with an average yearly salary > $70, 000.
*/
SELECT
    first_quater_job_postings.job_title_short,
    first_quater_job_postings.job_posted_date::DATE,
    first_quater_job_postings.salary_year_avg
FROM(
    SELECT *
    FROM january_jobs
    UNION ALL
    SELECT *
    FROM february_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS first_quater_job_postings
WHERE
    first_quater_job_postings.salary_year_avg > 70000 AND
    first_quater_job_postings.job_title_short = 'Data Analyst'

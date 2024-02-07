USE md_water_services;
SHOW TABLES;
SELECT * FROM data_dictionary;
-- Clustering Data
SELECT * FROM employee;
-- Updating the empty email addresses for employees for administrative purposes
SELECT
	CONCAT(
	LOWER(REPLACE(employee_name,' ','.')),'@ndogowater.gov') AS new_email-- Replacng the space with a full stop
FROM 
	employee;
-- Exiting safe update model
SET SQL_SAFE_UPDATES = 0;
UPDATE employee
	SET email = CONCAT(
	LOWER(REPLACE(employee_name,' ','.')),'@ndogowater.gov');
SELECT * FROM employee;

-- Checking for errors in phone_number
SELECT
	LENGTH(phone_number)
FROM
	employee;
-- We have 13 characters while, the phone_number should be 12 characters long. We need to correct this error by triming what could be white spaces
SELECT
	LENGTH(TRIM(phone_number))
FROM
	employee;
UPDATE 
	employee
SET 
	phone_number = TRIM(phone_number);
SELECT
	LENGTH(phone_number) AS phone_no_length
FROM
	employee;
    
-- Where do employees live
SELECT 
employee_name,
province_name,
town_name
FROM employee;
	-- a. Counting how many employees live in each town
SELECT
	town_name,
    COUNT(town_name) AS no_of_employees_per_town
FROM
	employee	
GROUP BY town_name
ORDER BY no_of_employees_per_town ASC;
-- How many workers are living in smaller communities in the rural parts of Maji Ndogo
	SELECT
		COUNT(town_name) AS no_of_employees_in_rural_communities
	FROM
		employee
	WHERE town_name = 'Rural';
-- 29 workers live here

-- Retreiving data on field surveyors

SELECT
	COUNT(DISTINCT(assigned_employee_id)) AS no_of_field_surveyors
FROM employee
WHERE
	position = 'Field Surveyor';
-- We had 29 Field surveyors

-- Developing a list for the top 3 best surveyors i.e those with the most visits
SELECT
	assigned_employee_id,
	COUNT(assigned_employee_id) AS number_of_visits_by_surveyor
FROM 
	visits
GROUP BY
	assigned_employee_id
ORDER BY number_of_visits_by_surveyor DESC
LIMIT 3;

-- The top 3 field surveyors are '1,30,34'
	-- Creating a information result set for these specific id's
SELECT 
	employee_name,
    email,
    phone_number
FROM 
	employee
WHERE assigned_employee_id IN (1,30,34);

-- Analysing locations
SELECT
	*
FROM location;

-- Number of records per town
SELECT
    town_name,
    COUNT(town_name) AS records_per_town
FROM
	location
GROUP BY
	town_name
ORDER BY
	records_per_town DESC;
    
-- Number of records per province
SELECT
    province_name,
    COUNT(province_name) AS records_per_province
FROM
	location
GROUP BY
	province_name
ORDER BY
	records_per_province DESC;

-- Number of records per location
SELECT
    location_type,
    COUNT(location_type) AS records_per_location
FROM
	location
GROUP BY
	location_type
ORDER BY
	records_per_location DESC;
-- Evaluating the result set as a percentage
SELECT ROUND((23740/(23740+15910))*100,0);
-- 60% of the water resources are located in rural communities


-- Diving into the sources
SELECT 
	* 
FROM
	water_source;
	-- 1. How many people did we survey in total?
		SELECT 
			SUM(number_of_people_served) AS total_number_of_people_surveyed
		FROM
			water_source;
		-- The total number of people surveyed is '27628140'
	
		-- 2. How many well, taps and rivers are there?
        SELECT 
			type_of_water_source,
            COUNT(type_of_water_source) AS number_of_sources
		FROM
			water_source
		GROUP BY type_of_water_source
        ORDER BY number_of_sources DESC;

	-- 3. How many people share particular types of water sources on average?
        SELECT 
			type_of_water_source,
            ROUND(AVG(number_of_people_served),0) AS average_number_of_pple_served
		FROM
			water_source
		GROUP BY type_of_water_source
        ORDER BY average_number_of_pple_served DESC;

-- 4. How many people are getting water from each type of source?
		SELECT 
			type_of_water_source,
			SUM(number_of_people_served) AS Total_number_of_people_served_per_source
        FROM
			water_source
		GROUP BY
			type_of_water_source;

		-- We can represent this information as a percentage of the total
			SELECT 
				type_of_water_source,
                ROUND((SUM(number_of_people_served)/27628140)*100,0) AS percentage_of_the_population_served
			FROM
				water_source
			GROUP BY
				type_of_water_source
			ORDER BY
				percentage_of_the_population_served DESC;

-- START OF A SOLUTION

-- We want to rank the water sources by the number of people they serve
SELECT 
    type_of_water_source,
    SUM(number_of_people_served) AS population_served,
    RANK() OVER (
        ORDER BY SUM(number_of_people_served) DESC
    ) AS rank_by_population
FROM
    water_source
GROUP BY 
    type_of_water_source;
-- We should either fix either shared_tap or well first because of they are rank 1 and 2 respectively.

-- A new dilemma arises, which taps or well should we fix first?
-- Approach : The most used sources should really be fixed first
SELECT * FROM water_source;
SELECT
    source_id,
    type_of_water_source,
    number_of_people_served,
    RANK() OVER (
    ORDER BY number_of_people_served DESC) AS priority_rank
FROM 
    water_source
;



-- Analysing Queries
USE md_water_services;
SELECT * FROM visits;
-- Question 1: How long did the survey take?
SELECT
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS total_survey_period
FROM
    visits;
-- The survey took 924 days, approximately 2.5 years

-- Question 2: What is the average total queue time for water?
SELECT * FROM visits;

-- We need toexclude sources with zero queue times
SELECT
    ROUND(AVG(NULLIF(time_in_queue, 0)),0) AS Average_queue_time
FROM
    visits
WHERE
    time_in_queue IS NOT NULL;
-- Turns out the average queue time in 123 minutes

-- Question 3: What is the average quetime for different days?
SELECT
	DAYNAME(time_of_record) AS Day_of_record,
	ROUND(AVG(NULLIF(time_in_queue,0)),0) AS average_time_in_queue
FROM
	visits
GROUP BY
	Day_of_record;
    
-- Question 4: How can we communicate this information efficiently?

-- We can also look at what time during the day people collect water
SELECT
	TIME_FORMAT(TIME(time_of_record),'%H:00') AS hour_of_day,
    ROUND(AVG(time_in_queue),0) AS avg_queue_time
FROM
	visits
GROUP BY
	hour_of_day;

-- Building my pivot table 😊
SELECT
	TIME_FORMAT(TIME(time_of_record),'%H:00') AS hour_of_day,
    -- Sunday
    ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Sunday,
    -- Monday
    ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Monday,
	-- Tuesday
    ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Tuesday,
        -- Wednesday
        ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Wednesday,
        -- Thursday
        ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Thursday,
        -- Friday
        ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Friday,
        -- Saturday
        ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
		ELSE NULL
	END),0)
		AS Saturday
FROM
	visits
WHERE 
	time_in_queue != 0 -- excludes other sources with 0 queue times.
GROUP BY
	hour_of_day
ORDER BY
	hour_of_day;

					-- 'We can now start shaping the new face of maji ndogo's water access and infrastructure🥳'

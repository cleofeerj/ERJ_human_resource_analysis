-- ----------------------------------- HUMAN RESOURCE ANALYSIS -----------------------------------
-- PROCEDURES:
-- 1.) DUPLICATE DATASET **** DONE ***
-- 2.0) CHANGE THE "id" name to "emp_id"
-- 2.1) STANDARDIZE DATA TYPES
-- 3.0) ADD COLUMN - "age"
-- 3.1) CLEAN THE OUTLIERS such as NEGATIVE Values
-- 4.) ANSWER EVERY QUESTION FOR ANALYSIS

SELECT @@sql_mode;
SET sql_mode = '';

-- ----------------------------------- START -----------------------------------
USE hr_data_dtset;
SELECT * FROM `human resources`;

-- 1.) DUPLICATE DATASET

CREATE TABLE hr_dataset_dupli LIKE `human resources`; -- CREATE DUPLICATE TABLE
INSERT hr_dataset_dupli SELECT * FROM `human resources`; -- INSERT THE VALUES FROM ORIGINAL TABLE

SELECT * FROM hr_dataset_dupli;

-- 2.0) CHANGE "ï»¿id" to emp_id

ALTER TABLE hr_dataset_dupli
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL; -- FROM "ï»¿id" TO "emp_id"

DESC hr_dataset_dupli;
SELECT * FROM hr_dataset_dupli;

-- 2.1) STANDARDIZE DATA TYPES - hire date && birthdate && term date

-- FOR "BIRTHDATE" 

-- Check if the 'birthdate' column contains slashes ('/'), indicating a MM/DD/YYYY format.
UPDATE hr_dataset_dupli
SET birthdate = CASE
		-- Convert the string date from MM/DD/YYYY format to a DATE object using STR_TO_DATE,
        -- and then format it to the standard YYYY-MM-DD format using DATE_FORMAT.
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;


-- FOR "HIRE DATE"
UPDATE hr_dataset_dupli
SET hire_date = CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END;

SELECT * FROM hr_dataset_dupli;

-- SINCE hire_date &&&& birthdate are changed to object, change the data type FROM text to DATE

ALTER TABLE hr_dataset_dupli
MODIFY COLUMN birthdate DATE;

ALTER TABLE hr_dataset_dupli
MODIFY COLUMN hire_date DATE;

-- FOR "TERMDATE" 
UPDATE hr_dataset_dupli
		-- Convert the `termdate` string into a DATE-only format (`YYYY-MM-DD`)
		-- Use STR_TO_DATE to parse the string into a DATETIME object
        -- The input format is '%Y-%m-%d %H:%i:%s UTC', matching values like '2021-02-25 13:43:01 UTC'
SET termdate = DATE(STR_TO_DATE(TRIM(termdate), '%Y-%m-%d %H:%i:%s UTC'))
            -- Trim leading and trailing spaces from the `termdate` value to avoid errors
WHERE termdate IS NOT NULL AND TRIM(termdate) != '';

-- MODIFIED THE BLANK VALUES TO SET THE DATA TYPE PROPERLY

UPDATE hr_dataset_dupli
SET termdate = NULL
WHERE termdate = '';

-- SET DATA TYPE TO DATE, FROM text to DATE

ALTER TABLE hr_dataset_dupli
MODIFY COLUMN termdate DATE;


SELECT COUNT(termdate) FROM hr_dataset_dupli WHERE termdate = '';

-- ADD COLUMN 'age'

ALTER TABLE hr_dataset_dupli
ADD COLUMN age INT;

SELECT * FROM hr_dataset_dupli;

-- timestampdiff gets the difference between the birthdate (start) and CURDATE() (current date)
-- the YEAR specifies difference in terms of years

UPDATE hr_dataset_dupli
SET age = timestampdiff(YEAR, birthdate, CURDATE());


-- 3.1) CLEAN THE OUTLIERS such as NEGATIVE Values
-- Determine the MIN and Max Values for outliers, and count those negative values

SELECT MIN(age), MAX(age) FROM hr_dataset_dupli;

SELECT COUNT(age) FROM hr_dataset_dupli WHERE age < 1;

-- totaling 967 negative


-- Replaced NULL values to indicate active in service
UPDATE hr_dataset_dupli
SET termdate = '0000-00-00'
WHERE termdate IS NULL;


-- PHASE 2: QUESTION ANSWERING

-- What is the gender breakdown of employees in the company?

SELECT gender, count(*) AS Gender_Count
FROM hr_dataset_dupli WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;


-- What is the race/ethnicity breakdown of employees in the company?

SELECT race, count(*) AS Race_Count
FROM hr_dataset_dupli WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race ORDER BY count(*) DESC;


-- What is the age distribution of employees in the company?

SELECT MIN(age), MAX(age)
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00';

SELECT 
	CASE 
		WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65+'
	END AS Age_Group, gender,
    COUNT(*) AS AgeGroup_Count
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY Age_Group, gender
ORDER BY Age_Group, gender;


-- How many employees work at headquarters versus remote locations?

SELECT location, COUNT(*) AS Workers_per_Location
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location;


-- What is the average length of employment for employees who have been terminated?

SELECT 
	round(avg((datediff(termdate, hire_date)))/365, 0) AS employment_rate_years
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate != '0000-00-00'AND termdate <= CURDATE();


-- How does the gender distribution vary across departments and job titles?

SELECT department, gender, COUNT(*) AS Gender_Count_dp
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY department, gender
ORDER BY department ASC;


-- What is the distribution of job titles across the company?

SELECT jobtitle, COUNT(*) AS Job_Count
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle ASC;


-- Which department has the highest turnover rate?

SELECT department, total_count, terminated_count,
terminated_count/total_count AS termination_rate
FROM (
	SELECT department,
    count(*) AS total_count,
    SUM( CASE WHEN termdate != '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminated_count
    FROM hr_dataset_dupli WHERE age >= 18
    GROUP BY department
    ) AS subquery
ORDER BY termination_rate DESC;





SELECT * FROM hr_dataset_dupli;


-- What is the distribution of employees across locations by state?

SELECT location_state, COUNT(*) AS State_emp_count
FROM hr_dataset_dupli
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY State_emp_count DESC;


-- How has the company's employee count changed over time based on hire and term dates?

SELECT year, hires, terminations, 
	hires - terminations AS net_change,
    round((hires - terminations)/hires * 100, 2) AS net_change_percentage
FROM(
	SELECT 
    YEAR(hire_date) AS year,
    count(*) as hires,
    SUM(CASE WHEN termdate != '0000-00-00' AND termdate <= curdate() THEN 1 ELSE 0 END) AS terminations
    FROM hr_dataset_dupli
    WHERE age >= 18
    GROUP BY YEAR(hire_date)
    ) AS subquery
ORDER BY year ASC;


-- What is the tenure distribution for each department?

SELECT department, round(avg(datediff(termdate, hire_date)/365),0) AS avg_tenure
FROM hr_dataset_dupli
WHERE termdate <= curdate() AND termdate != '0000-00-00' AND age >= 18
GROUP BY department;

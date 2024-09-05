/* Comprehensive Analysis of AI Powered Job Market Trends*/

--Step 1: Data Cleaning and Filtering.
--1.1. Understanding the Data I'm working with. 

Select * from [Portfolio Project AI]..[AI_job_market_insights]

--1.2 Checking for Duplicates. 

SELECT *, COUNT(*) AS Count
FROM AI_job_market_insights
GROUP BY Job_Title, Industry, Location, Company_Size, AI_Adoption_Level, Automation_Risk, Required_Skills, Salary_USD, Remote_Friendly, Job_Growth_Projection
HAVING COUNT(*) > 1;

----No Duplicated Rows were found, however, had I filtered just by Job_Title, Industry, Location, and Company_Size, I would have found 29 Rows duplicated,
----and then proceded to remove them by using the next Query. 

--WITH CTE AS (
--    SELECT *,
--           ROW_NUMBER() OVER(PARTITION BY Job_Title, Industry, Location, Company_Size ORDER BY Job_Title) AS RowNum
--    FROM AI_job_market_insights
--)
--DELETE
--FROM CTE
--WHERE RowNum > 1

----As a precaution, I would Run it first as SELECT instead of DELETE. That way I can make sure to see exactly which data will be removed and can later delete it with more confidence. 

--1.3. Check for Missing Values.

SELECT *
FROM AI_job_market_insights
WHERE Job_Title IS NULL
   OR Industry IS NULL
   OR Location IS NULL
   OR Company_Size IS NULL
   OR AI_Adoption_Level IS NULL
   OR Automation_Risk IS NULL
   OR Required_Skills IS NULL
   OR Salary_USD IS NULL;

----No Null Data was found in this Dataset. 

--1.4. Standardize Data Formats

   UPDATE AI_job_market_insights
SET Location = UPPER(Location),
    Job_Title = UPPER(Job_Title),
    Industry = UPPER(Industry),
    Required_Skills = UPPER(Required_Skills);

----Job_Title, Industry, Location and Required Skills were Capitalized for consistency. Leaving in lower case only Categorical Columns. 

--1.5. Filter Data for Relevant Industries and Locations
----Creating Filtered table for later usage in visualization.

SELECT *
INTO AI_job_market_filtered
FROM AI_job_market_insights
WHERE 
  (Industry IN ('Technology', 'Finance') 
   AND Location IN ('New York', 'London', 'San Francisco'))
OR 
  (Industry IN ('Healthcare', 'Education') 
   AND Location IN ('Paris', 'Berlin', 'Singapore'))
OR 
  (Industry IN ('Entertainment', 'Telecommunications') 
   AND Location IN ('Dubai', 'Tokyo', 'Sydney'));

--1.6. Review and Validate the Cleaned Data
  
SELECT COUNT(*) AS TotalRows, 
       COUNT(DISTINCT Job_Title) AS UniqueJobTitles, 
       COUNT(DISTINCT Location) AS UniqueLocations
FROM AI_job_market_insights;

SELECT COUNT(*) AS TotalRows, 
       COUNT(DISTINCT Job_Title) AS UniqueJobTitles, 
       COUNT(DISTINCT Location) AS UniqueLocations
FROM AI_job_market_filtered;

--Step 2: Aggregating Data for Salary Analysis.
--2.1: Calculate Average Salary by Job Title.

SELECT Job_Title, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
FROM AI_job_market_filtered
GROUP BY Job_Title
ORDER BY AvgSalary DESC;

--2.2: Calculate Average Salary by Job Title and Industry

SELECT Job_Title, Industry, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
FROM AI_job_market_filtered
GROUP BY Job_Title, Industry
ORDER BY AVG(Salary_USD) DESC;

--2.3: Calculate Average Salary by Location

SELECT Location, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
FROM AI_job_market_filtered
GROUP BY Location
ORDER BY AVG(Salary_USD) DESC;

--2.4: Calculate Salary by Job Title, Industry, and Location

SELECT Job_Title, Industry, Location, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
FROM AI_job_market_filtered
GROUP BY Job_Title, Industry, Location
ORDER BY AVG(Salary_USD) DESC;

--2.5: Store the Aggregated Data

SELECT Job_Title, Industry, Location, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
INTO AI_Salary_Aggregates
FROM AI_job_market_filtered
GROUP BY Job_Title, Industry, Location;

Select *
From [Portfolio Project AI].dbo.AI_Salary_Aggregates

--Step 3: Advanced Correlation Analysis Using Joins, CTEs, and Correlations
--3.1: Using CTEs for Correlation Between AI Adoption Levels and Automation Risk

WITH AI_Automation_CTE AS (
    SELECT AI_Adoption_Level, Automation_Risk, FORMAT(AVG(Salary_USD), 'C', 'en-US') AS AvgSalary
    FROM AI_job_market_filtered
    GROUP BY AI_Adoption_Level, Automation_Risk
)
SELECT AI_Adoption_Level, Automation_Risk, AvgSalary
FROM AI_Automation_CTE
ORDER BY AI_Adoption_Level, Automation_Risk;


--3.2: Joining filtered and aggregates Tables to Explore Salary by Company Size and Job Growth

ALTER TABLE AI_Salary_Aggregates
ADD NumericSalary FLOAT;

UPDATE AI_Salary_Aggregates
SET NumericSalary = CAST(REPLACE(REPLACE(AvgSalary, '$', ''), ',', '') AS FLOAT);

ALTER TABLE AI_Salary_Aggregates
DROP COLUMN AvgSalary;

EXEC sp_rename 'AI_Salary_Aggregates.NumericSalary', 'AvgSalary', 'COLUMN';

SELECT f.Company_Size, f.Job_Growth_Projection, FORMAT(AVG(a.AvgSalary), 'C', 'en-US') as AvgSalary
FROM AI_job_market_filtered f
JOIN AI_Salary_Aggregates a
ON f.Job_Title = a.Job_Title
   AND f.Industry = a.Industry
   AND f.Location = a.Location
GROUP BY f.Company_Size, f.Job_Growth_Projection, a.AvgSalary
ORDER BY AVG(a.AvgSalary) DESC;

--3.3: Correlating Skills with Salary Using Joins and CTE

WITH Skills_CTE AS (
    SELECT i.Required_Skills, a.AvgSalary
    FROM AI_job_market_insights i
    JOIN AI_Salary_Aggregates a
    ON i.Job_Title = a.Job_Title
       AND i.Industry = a.Industry
       AND i.Location = a.Location
)
SELECT Required_Skills, ROUND(AVG(AvgSalary), 2) AS AvgSkillSalary
FROM Skills_CTE
GROUP BY Required_Skills
ORDER BY AvgSkillSalary DESC;

--3.4: Combining Insights with a Full Correlation Using CTE and Join

WITH Full_Correlation_CTE AS (
    SELECT f.AI_Adoption_Level, f.Automation_Risk, f.Company_Size, a.AvgSalary
    FROM AI_job_market_filtered f
    JOIN AI_Salary_Aggregates a
    ON f.Job_Title = a.Job_Title
       AND f.Industry = a.Industry
       AND f.Location = a.Location
)
SELECT AI_Adoption_Level, Automation_Risk, Company_Size, ROUND(AVG(AvgSalary), 2) AS AvgCorrelatedSalary
FROM Full_Correlation_CTE
GROUP BY AI_Adoption_Level, Automation_Risk, Company_Size
ORDER BY AvgCorrelatedSalary DESC;


--3.5: Storing Results for Future Use

SELECT AI_Adoption_Level, Automation_Risk, Company_Size, Required_Skills, ROUND(AVG(Salary_USD), 2) AS AvgSalary
INTO AI_Correlation_Analysis
FROM AI_job_market_filtered
GROUP BY AI_Adoption_Level, Automation_Risk, Company_Size, Required_Skills;

--Step 4: Filtering Data for Remote Work Analysis
--4.1: Categorize Jobs Based on Remote Work

SELECT Job_Title, 
       Industry, 
       Location, 
       Salary_USD, 
       Remote_Friendly, 
       CASE 
          WHEN Remote_Friendly = 'Yes' THEN 'Remote Job'
          ELSE 'On-Site Job'
       END AS Work_Type
FROM AI_job_market_filtered;


--4.2: Compare Average Salary Between Remote and On-Site Jobs

SELECT Work_Type, 
       Location, 
       Industry, 
       ROUND(AVG(Salary_USD), 2) AS AvgSalary
FROM (
    SELECT Job_Title, 
           Industry, 
           Location, 
           Salary_USD, 
           CASE 
              WHEN Remote_Friendly = 'Yes' THEN 'Remote Job'
              ELSE 'On-Site Job'
           END AS Work_Type
    FROM AI_job_market_filtered
) AS JobClassification
GROUP BY Work_Type, Location, Industry
ORDER BY AvgSalary DESC;

--4.3: Analyze the Distribution of Remote vs. On-Site Jobs by Industry

SELECT Industry, 
       Work_Type, 
       COUNT(*) AS JobCount,
       CONCAT(ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Industry), 2), ' %') AS Percentage
FROM (
    SELECT Industry, 
           CASE 
              WHEN Remote_Friendly = 'Yes' THEN 'Remote Job'
              ELSE 'On-Site Job'
           END AS Work_Type
    FROM AI_job_market_filtered
) AS JobTypeClassification
GROUP BY Industry, Work_Type
ORDER BY Percentage DESC;

--4.4: Filter Jobs by High Salary and Remote Work

SELECT Job_Title, 
       Industry, 
       Location, 
       ROUND(Salary_USD, 2) 
       Remote_Friendly
FROM AI_job_market_filtered
WHERE Remote_Friendly = 'Yes'
  AND Salary_USD > 100000
ORDER BY Salary_USD DESC;

--4.5: Store Remote Work Analysis Results

SELECT Job_Title, 
       Industry, 
       Location, 
       ROUND(Salary_USD, 2) AS Salary, 
       Remote_Friendly, 
       CASE 
          WHEN Remote_Friendly = 'Yes' THEN 'Remote Job'
          ELSE 'On-Site Job'
       END AS Work_Type
INTO Remote_Work_Analysis
FROM AI_job_market_filtered;

--Step 5: Identifying High-Growth AI Job Roles
--5.1: Identifying Job Roles with High Growth Projection Using CASE and CTE

WITH Growth_CTE AS (
    SELECT Job_Title, 
           Industry, 
           Location, 
           ROUND(Salary_USD, 2) AS Salary,
           Job_Growth_Projection,
           CASE 
              WHEN Job_Growth_Projection = 'Growth' THEN 'High Growth'
              ELSE 'Not High Growth'
           END AS Growth_Status
    FROM AI_job_market_filtered
    WHERE Job_Growth_Projection = 'Growth'
)
SELECT Job_Title, Industry, Location, Salary, Growth_Status
FROM Growth_CTE
ORDER BY Salary DESC;

--5.2: Analyze Salary Trends in High-Growth Roles Using Window Functions

SELECT Job_Title, 
       Industry, 
       Location, 
       Salary_USD, 
       Job_Growth_Projection,
       ROUND(AVG(Salary_USD) OVER (PARTITION BY Industry), 2) AS Industry_AvgSalary,
       ROUND(AVG(Salary_USD) OVER (PARTITION BY Location), 2) AS Location_AvgSalary
FROM AI_job_market_filtered
WHERE Job_Growth_Projection = 'Growth'
ORDER BY Salary_USD DESC;

--5.3: Identify the Top Industries for High-Growth Jobs Using Aggregation

SELECT Industry, 
       COUNT(*) AS HighGrowthJobCount, 
       ROUND(AVG(Salary_USD), 2) AS AvgSalary
FROM AI_job_market_filtered
WHERE Job_Growth_Projection = 'Growth'
GROUP BY Industry
ORDER BY HighGrowthJobCount DESC, AvgSalary DESC;


-- 5.4: Correlate AI Adoption Level and High-Growth Jobs Using CTE and CASE

WITH AI_Growth_CTE AS (
    SELECT Job_Title, 
           Industry, 
           AI_Adoption_Level, 
           Job_Growth_Projection, 
           Salary_USD,
           CASE 
              WHEN AI_Adoption_Level = 'High' THEN 'High AI Adoption'
              WHEN AI_Adoption_Level = 'Medium' THEN 'Medium AI Adoption'
              ELSE 'Low AI Adoption'
           END AS AI_Level_Category
    FROM AI_job_market_filtered
    WHERE Job_Growth_Projection = 'Growth'
)
SELECT AI_Level_Category, 
       COUNT(*) AS HighGrowthJobCount, 
       ROUND(AVG(Salary_USD), 2) AS AvgSalary
FROM AI_Growth_CTE
GROUP BY AI_Level_Category
ORDER BY HighGrowthJobCount DESC, AvgSalary DESC;

--5.5: Filter for High-Paying High-Growth Jobs Using Advanced Filtering

SELECT Job_Title, 
       Industry, 
       Location, 
       ROUND(Salary_USD, 2) AS Salary, 
       Job_Growth_Projection
FROM AI_job_market_filtered
WHERE Job_Growth_Projection = 'Growth'
  AND Salary_USD > 120000
ORDER BY Salary_USD DESC;

--5.6: Store High-Growth Job Analysis Results

SELECT Job_Title, 
       Industry, 
       Location, 
       Salary_USD, 
       Job_Growth_Projection
INTO High_Growth_Job_Analysis
FROM AI_job_market_filtered
WHERE Job_Growth_Projection = 'Growth';

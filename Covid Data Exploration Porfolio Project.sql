/*	
Covid 19 Data Exploration
*/

-- Data about Covid 19 total cases affected and deaths numbers in addition to other data
-- Sorted by countries and date
SELECT *
FROM ['CovidDeath']
ORDER BY 3,4;


-- Data about Covid 19 vaccination and total number of being vaccinated in addition to other data
-- Sorted by countries and date

SELECT *
FROM ['CovidVaccinations']
ORDER BY 3, 4;


-- Snapshot of the data we are going to be sarting with

SELECT TOP 20
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM ['CovidDeath']
ORDER BY 1, 2 ;

-- Getting the number of Covid 19 cases in addition to number of deaths
-- From the beginning of the epidemic

SELECT TOP 1
	total_cases,
	total_deaths
FROM ['CovidDeath']
ORDER BY 1 DESC;




-- Looking at Total Deaths vs Total Cases for all countries
-- Calculating death rate for infected cases per day for each country 
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases) *100 AS Death_percentage
FROM ['CovidDeath']
ORDER BY 1, 2 ;

-- Total Deaths vs Total Cases in the United States 
-- Probability of death if you contract covid in the United States

SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	total_deaths/total_cases *100 AS USA_Death_percentage
FROM ['CovidDeath']
WHERE location LIKE '%United%States%'
ORDER BY 1, 2 ;

-- Total Cases vs Population for each country
-- Showing percentage of people affected with covid for each country

SELECT 
	location,
	date,
	population,
	total_cases,
	(total_cases/population) *100 AS Percent_Population_Infected
FROM ['CovidDeath']
ORDER BY 1, 2 ;


-- Top 10 Countries with Highest Death Count per Population

SELECT TOP 10
	location,
	MAX(CONVERT(int,total_deaths)) AS Max_Total_Death
FROM ['CovidDeath']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_total_death DESC;


-- Countries with Highest Infection Rate compared to Population

SELECT 
	Location,
	Population, 
	MAX(total_cases) AS Max_Infection_Count,
	Max((total_cases/population))*100 AS Percent_Population_Infected
FROM ['CovidDeath']
GROUP BY Location, Population
ORDER BY Percent_Population_Infected DESC


-- Total number of deaths from the start of the epidemic for each country 
-- Sorting the number of deaths from highest to lowest

SELECT
	location,
	SUM(CAST(new_deaths AS int)) AS Sum_Total_Death
FROM ['CovidDeath']
WHERE continent IS NOT NULL
GROUP BY  location
ORDER BY Sum_Total_Death DESC;


-- The top 20 days with the Highest number of new cases across the world

SELECT TOP 20
	date, 
	MAX(CAST(new_cases AS int)) max_cases_per_day
FROM ['CovidDeath']
GROUP BY date
ORDER BY 2 DESC;


-- The top 20 days with the Highest number of new deaths across the world

SELECT TOP 20
	date, 
	MAX(CAST(new_deaths AS int)) AS max_deaths_per_day
FROM ['CovidDeath']
GROUP BY date
ORDER BY 2 DESC;


-- Now we will deal with data about continents
-- Looking at total number of deaths and cases for each contintent in addition to death percentage
-- sorted by number of cases from highest to lowest

SELECT 
	Continent,
	Total_Death_Count,
	Total_Cases_Count,
	(CONVERT(float, Total_Death_Count) / CONVERT(float, Total_Cases_Count))*100 AS Death_Percentage
FROM
(SELECT 
	coalesce(continent, location) AS Continent, 
	MAX(cast(total_deaths AS int)) AS Total_Death_Count,
	MAX(cast(total_cases AS int)) AS Total_Cases_Count
FROM ['CovidDeath']
GROUP BY coalesce(continent, location)) AS Sub_1
WHERE Continent IN('Africa','Europe','North America','South America','Oceania','Asia')
ORDER BY 3 DESC;

-- Joining two data sets ( CovidDeath and CovidVaccinations) into one table

SELECT *
FROM ['CovidDeath'] dea  -- Aliasing the table as dea
JOIN ['CovidVaccinations'] vac  -- Aliasing the table as vac
ON dea.location = vac.location 
AND dea.date = vac.date;

-- Tracking number of vaccinations for each country around the world
-- Sorting from highest to lowest

SELECT 
	location,
	MAX(CAST(total_vaccinations AS float)) AS Vaccinations_Count
FROM ['CovidVaccinations']
WHERE total_vaccinations IS NOT NULL 
AND continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;


-- Calculate total number of people that has been fully vaccinated and population in each country
-- Sorting from highest to lowest

SELECT 
	dea.location,
	dea.population,
	MAX(CAST(vac.people_fully_vaccinated AS float)) AS total_people_fully_vac
FROM ['CovidVaccinations'] vac
JOIN ['CovidDeath'] dea
ON vac.date = dea.date 
AND vac.location = dea.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
ORDER BY 3 DESC;


/* Using subqueries to calculate total number of people that has been fully vaccinated in each country
in addition to Percantage of fully vaccinated people from total population 
Sorted by the total percentage from lowest to highest */

SELECT *
FROM
(
SELECT *, (total_people_fully_vac / population) *100 total_people_fully_vac_percantage
FROM 
(SELECT 
	dea.location,
	dea.population,
	MAX(CAST(vac.people_fully_vaccinated AS float)) AS total_people_fully_vac
FROM ['CovidVaccinations'] vac
JOIN ['CovidDeath'] dea
ON vac.date = dea.date 
AND vac.location = dea.location
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population) AS sub_1) AS sub_2
WHERE total_people_fully_vac_percantage < 100
ORDER BY 4 ASC;



-- Showing population that has recieved at least one Covid Vaccine in each country
-- partitioning by location and date
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
-- Here we will partition the total number of people vaccinated by location and date 
	SUM(CAST(vac.new_vaccinations AS int))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Partitioned_People_Vaccinated
From ['CovidDeath'] dea
JOIN ['CovidVaccinations'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;


/* Using CTE on resulted partitioned table for calculating 
the percentage of Population that has recieved at least one Covid Vaccine
the results are partitioned by location and date*/

WITH part_table AS
(SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Partitioned_People_Vaccinated
From ['CovidDeath'] dea
JOIN ['CovidVaccinations'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT *, (Partitioned_People_Vaccinated / population)* 100 AS Partitioned_People_Vaccinated_Percantage
FROM part_table



-- Using Temp Table to perform calculation on the partitioned table in the previous query

CREATE TABLE #PercentPopulationVaccinated
(
	Continent varchar(255),
	Location varchar(255),
	Date datetime,
	Population float,
	New_Vaccinations numeric,
	Partitioned_People_Vaccinated float
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Partitioned_People_Vaccinated
FROM ['CovidDeath'] dea
JOIN ['CovidVaccinations'] vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *
FROM #PercentPopulationVaccinated;



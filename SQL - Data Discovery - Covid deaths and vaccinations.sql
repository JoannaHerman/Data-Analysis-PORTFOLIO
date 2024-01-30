SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland' 
ORDER BY 1,2

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland'

/* extracting information about each location's highest infection count and the corresponding infection percentage based on the population. 
The results are grouped by location and population, with the output ordered in descending order by infection percentage. */
	
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC

/* WHERE CONTINTNT IS NOT NULL - quick fix of database errors where continent is null and location instead of country shows continent 
	(continent: Null, location: Asia) */
	
SELECT location, population, continent, MAX(cast(total_deaths AS int)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, continent
ORDER BY DeathCount DESC

/* calculates the total cases, total deaths, and the death percentage for each date. The results are grouped by date and filtered to include only 
records where the continent is not null. The final output is ordered by date and total cases. */
	
SELECT  date, SUM(new_cases) AS [total cases], SUM(cast(new_deaths AS int)) AS [total deaths], (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercantage --
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Poland' 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY  1,2


--------VACCINATIONS

/* conducts an inner join between the CovidDeaths and CovidVaccinations tables from the PortfolioProject database. 
The join is based on the common columns 'location' and 'date', merging information from both tables into a single result set */	

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = dea.date

/* xtracts relevant columns, calculates the cumulative number of people vaccinated over time for each location, and filters the results for non-null continents. 
	The final output is ordered by location and date */

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

/* creates a CTE called PopVSVac by merging COVID death and vaccination data from the CovidDeaths and CovidVaccinations tables. 
	It calculates the cumulative number of people vaccinated over time for each location and filters the results for non-null continents. 
	The final query selects all columns from the CTE and adds a calculated column representing the percentage of the population vaccinated. */

WITH PopVSVac (continent, location, date, population, new_vaccinations, PeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac 
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,(PeopleVaccinated/population)*100 AS PercentageVaccinated
FROM PopVSVac

/* creates a temporary table #PercentPopulationVaccinated and populates it by merging COVID death and vaccination data from the CovidDeaths and 
	CovidVaccinations tables. The table includes columns for continent, location, date, population, new vaccinations, 
	and a rolling total of vaccinated people. The final query adds a calculated column for the percentage of the population vaccinated. */
	
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated

/* creates a view named PercentagePopulationVaccinated by combining COVID death and vaccination data from the CovidDeaths and CovidVaccinations tables.
	The view includes columns for continent, location, date, population, new vaccinations, and a rolling total of vaccinated 
	people. Additionally, it filters out records where the continent is null. The ORDER BY clause is currently commented out, so the result set is not 
	explicitly ordered. This view provides a dynamic, virtual representation of the calculated vaccination percentages for further analysis. */

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3 

--- SUMMARY - DESCRIPTION ----
/* This data exploration in SQL involves a series of queries and operations on COVID-19 datasets (CovidDeaths and CovidVaccinations) within the PortfolioProject 
database. Here's a summary of the purpose behind each command:
1. CovidDeaths Analysis:
	- Extracts all columns from the CovidDeaths table, ordered by the third and fourth columns (presumably date-related columns).
2. CovidVaccinations Analysis:
	- Extracts all columns from the CovidVaccinations table, ordered by the third and fourth columns (presumably date-related columns).
3. Specific Columns from CovidDeaths:
	- Selects specific columns (location, date, total_cases, new_cases, total_deaths, population) from CovidDeaths, ordered by location and date.
4. Poland's Death Percentage:
	- Calculates death percentages for Poland based on total cases and total deaths, ordering the results by location and date.
5. Poland's Infection Percentage:
	- Calculates infection percentages for Poland based on total cases and population, ordered by location.
6. Highest Infection Count by Location:
	- Groups data by location and population, calculating the highest infection count and corresponding infection percentage. 
	  Results are ordered by infection percentage in descending order.
7. Quick Fix for Continent Errors:
	- Addresses database errors where continent is null by filtering for records where continent is not null. Results include location, 
          population, continent, and the highest death count.
8. Daily COVID-19 Statistics:
	- Calculates total cases, total deaths, and death percentages for each date. Results are grouped by date, 
          with optional filtering for non-null continents.
9. Inner Join with Vaccination Data:
	- Conducts an inner join between CovidDeaths and CovidVaccinations tables based on common columns 'location' and 'date'.
10. People Vaccinated Over Time:
	- Extracts relevant columns and calculates the cumulative number of people vaccinated over time for each location. 
          Results are ordered by location and date.
11. CTE for Percentage of Population Vaccinated:
	- Creates a Common Table Expression (CTE) named PopVSVac to calculate cumulative vaccinated people over time. 
          The CTE is used to calculate the percentage of the population vaccinated.
12. Temporary Table for Population Vaccination:
	- Creates a temporary table #PercentPopulationVaccinated and populates it with COVID death and vaccination data. 
          Calculates the rolling total of vaccinated people and adds a column for the percentage of the population vaccinated.
13. View for Population Vaccination:
	- Creates a view named PercentagePopulationVaccinated by combining COVID death and vaccination data. 
          The view includes columns for continent, location, date, population, new vaccinations, and a rolling total of vaccinated people. 
          Records where the continent is null are excluded.

--- These SQL commands aim to analyze and derive meaningful insights from COVID-19 datasets, providing dynamic representations of vaccination percentages 
for further analysis. ---

*/ 

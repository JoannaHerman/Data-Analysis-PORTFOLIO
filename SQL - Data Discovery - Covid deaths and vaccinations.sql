/* Looking if everything works fine */

SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

/* Select data that we are going to be using */

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

/* Looking at Total Cases vs Total Deaths - how many cases in country, and then how many deaths per entire cases 
Example: 1000 people have been diagnosed; 10 people died; whats % of ppeople who died (whats the chance of person dying becouse of covid)
*/

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland' 
ORDER BY 1,2


/* Looking at total cases vs population - what % of population got infected*/

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Poland'

/* Looking at countries with highest inferction rate compared to population */

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC


/* Looking at countriest with highesr death count per population*/

SELECT location, population, continent, MAX(cast(total_deaths AS int)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --becouse if not that line location would be like continents mixed with countries
GROUP BY location, population, continent
ORDER BY DeathCount DESC

/* breaking things down by continent */

SELECT location, MAX(cast(total_deaths AS int)) AS DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL --becouse if not that line location would be like continents mixed with countries
GROUP BY location
ORDER BY DeathCount DESC

/* calculating everything for entire world */

SELECT  date, SUM(new_cases) AS [total cases], SUM(cast(new_deaths AS int)) AS [total deaths], (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercantage --
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Poland' 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY  1,2

/* sum of: cases, deaths, and death percentage */
--SELECT  SUM(new_cases) AS [total cases], SUM(cast(new_deaths AS int)) AS [total deaths], (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercantage --
--FROM PortfolioProject..CovidDeaths
----WHERE location = 'Poland' 
--WHERE continent IS NOT NULL
----GROUP BY date
--ORDER BY  1,2


--------VACCINATIONS
SELECT *
FROM PortfolioProject..CovidVaccinations

SELECT * 
FROM PortfolioProject..CovidDeaths
-- join

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = dea.date

/* Looking at total population vs vaccination - how many people in the world have been vaccinated (population vs vaccination) */

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM (CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

/* USING CTE to do further calculations - how many % of population is vaccinated */

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
FROM 
PopVSVac



-- USING TEMP TABLE where we insert into % of people vaccinated
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


-- creating view to store data for later visualizations

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3 

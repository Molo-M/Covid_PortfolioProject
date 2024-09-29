/*
Covid 19 Data Exploration (This Updated Data Set Includes 2024 Covid 19 Information)

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--QUERY 1: See the data
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL  -- When Continent is null, we are not give a country name in the "location" column, but a categorization
ORDER BY 3,4


-- QUERY 2: Here we can see all the categorizations of countries provided in the "location" column:

SELECT DISTINCT location
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
ORDER BY location
--OBSERVATION: We can see that countries were classified according to their income and their
--geographic location like which continent they belong to.


-- QUERY 3: Select Data that we are going to be starting with:

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- QUERY 4: Total Cases vs Total Deaths:
-- Shows likelihood of dying if you contract covid in Rwanda

SELECT Location, date, total_cases, total_deaths,
       CASE  -- For situations where total_cases is equal to zero
           WHEN total_cases = 0 THEN 0
           ELSE (total_deaths / total_cases) * 100
       END as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Rwanda%'
AND continent IS NOT NULL
ORDER BY 1, 2;
--OBSERVATION: Interesting to see that the percentage of infected people who died after being infected
--never surpassed 1.1% in Rwanda

-- QUERY 5: Total Cases vs Population:
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--Where location like '%Rwanda%'
WHERE continent IS NOT NULL
ORDER BY 1,2


-- QUERY 6: Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--Where location like '%Rwanda%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
--OBSERVATION: It was unexpected that Cyprus had the highest percent of people infected by Covid 19
--compared to its population. A staggering 77% of its population has been infected. Perhaps this
--also due its small population size. We can see that alot of the countries with high infection rates 
--compared to population are smaller countries.

-- BREAKING THINGS DOWN BY CONTINENT:

-- QUERY 7: Showing contintents with the highest death count per population

SELECT continent, MAX(population) AS TotalPopulation, MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
, MAX(cast(Total_deaths AS INT)) / MAX(population) AS PercentageDeathsPerPopulation
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
--ORDER BY TotalDeathCount DESC
ORDER BY PercentageDeathsPerPopulation DESC

--OBSERVATION: It seems that the total deaths by Covid 19 did not even reach 0.1 percent of any continent's
--population. According to these numbers the Covid pandemic cannot even compare to previous pandemics
--such as the Spanish Flu who mortality was around 1.1 percent of Europeans or the Black Plague
--which caused anywhere from 30 percent to 50 percent of European deaths.

-- QUERY 8: GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2
--OBSERVATION: The percentage of people infected by Covid 19 who died did not reach 1 percent.
--Based on rumors(unverified information) around that was passed around, it is assumed that 
--the percentage was much higher.

-- QUERY 9: Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(BIGINT, COALESCE(vac.new_vaccinations, 0))) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- QUERY 10: Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, COALESCE(vac.new_vaccinations, 0))) OVER (PARTITION BY dea.Location Order BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- QUERY 11: Using Temp Table to perform Calculation on Partition By in previous query

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
, SUM(CONVERT(BIGINT, COALESCE(vac.new_vaccinations, 0))) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- QUERY 12: Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, COALESCE(vac.new_vaccinations, 0))) OVER (Partition by dea.Location Order BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *
FROM PercentPopulationVaccinated

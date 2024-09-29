# Covid 19 Portfolio Project
This is a portfolio project using SQL queries to analyze the Covid 19 dataset which shows critical information such as locations, total cases, total deaths, total vaccinations , etc.

The Covid 19 dataset was used for this data analysis project. You can find it by visiting [*Our World in Data*](https://ourworldindata.org/covid-deaths)

**Skills used**: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

### QUERY 1      
See the data
```sql
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL  -- When Continent is null, we are not given a country name in the "location" column, but a categorization
ORDER BY 3, 4;
```
![query1](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_1.PNG)

### QUERY 2       
Here we can see all the categorizations of countries provided in the "location" column:
```sql
SELECT DISTINCT location
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
ORDER BY location;
--OBSERVATION: We can see that countries were classified according to their income and their
--geographic location like which continent they belong to.
```
![query2](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_2.PNG)

### QUERY 3    
Select Data that we are going to be starting with:
```sql
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2
```
![query3](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_3.PNG)

### QUERY 4    
Total Cases vs Total Deaths: Shows likelihood of dying if you contract covid in Rwanda
```sql
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
```
![query4](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_4.PNG)

### QUERY 5
Total Cases vs Population: Shows what percentage of population infected with Covid
```sql
SELECT location, date, population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--Where location like '%Rwanda%'
WHERE continent IS NOT NULL
ORDER BY 1,2
```
![query5](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_5.PNG)

### QUERY 6
Countries with Highest Infection Rate compared to Population:
```sql
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
```
![query6](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_6.PNG)

## BREAKING THINGS DOWN BY CONTINENT

### QUERY 7
Showing contintents with the highest death count per population:
```sql
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
```
![query7](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_7.PNG)

### QUERY 8
GLOBAL NUMBERS:
```sql
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2
--OBSERVATION: The percentage of people infected by Covid 19 who died did not reach 1 percent.
--Based on rumors(unverified information) around that was passed around, it is assumed that 
--the percentage was much higher.
```
![query8](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_8.PNG)

### QUERY 9
Total Population vs Vaccinations: Shows Percentage of Population that has recieved at least one Covid Vaccine
```sql
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CONVERT(BIGINT, COALESCE(vac.new_vaccinations, 0))) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3
```
![query9](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_9.PNG)

### QUERY 10
Using CTE to perform Calculation on Partition By in previous query:
```sql
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
```
![query10](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_10.PNG)

### QUERY 11
Using Temp Table to perform Calculation on Partition By in previous query:
```sql
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
```
![query11](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_11.PNG)

### QUERY 12
Creating View to store data for later visualizations:
```sql
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
```
![query12](https://github.com/Molo-M/Covid_PortfolioProject/blob/main/sql_images/Query_12.PNG)


# Thank You!

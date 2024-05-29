
SELECT *
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- SELECT location, date, total_cases, new_cases, total_deaths, population
-- FROM COVIDProject..CovidDeaths
-- WHERE continent IS NOT NULL
-- ORDER BY 1,2

-- Total Cases vs Total Deaths - Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS PercentPopulationInfected
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
-- WHERE LOCATION LIKE '%states%'
ORDER BY 1,2

-- exec sp_columns CovidDeaths

-- Highest infection rate compared to population
SELECT location, date, total_cases, (CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationInfected
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
-- WHERE LOCATION LIKE '%states%'
ORDER BY 1,2

-- Countries with highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationInfected
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

-- CONTINENT - Continent with the highest death count 
SELECT continent, MAX(total_deaths) AS TotalDeathCount --, MAX(CAST(total_deaths AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationDied
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- COUNTRY
SELECT continent, location, Population, MAX(total_deaths) AS TotalDeathCount --, MAX(CAST(total_deaths AS FLOAT)/CAST(population AS FLOAT))*100 AS PercentPopulationDied
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location, Population
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT))*100 AS DeathPercentage
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
-- WHERE LOCATION LIKE '%states%'
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT))*100 AS DeathPercentage
FROM COVIDProject..CovidDeaths
WHERE continent IS NOT NULL
-- WHERE LOCATION LIKE '%states%'
ORDER BY 1,2


-- Total Population vs Vaccinations (% of population vaccinated)

-- SELECT dea.continent, dea.location, dea.date, dea.population, COALESCE(vac.new_vaccinations,0) AS new_vaccinations, SUM(COALESCE(vac.new_vaccinations,0)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinations
-- FROM COVIDProject..CovidDeaths dea
-- JOIN COVIDProject..CovidVaccinations vac
-- ON dea.location=vac.location AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, 
COALESCE(vac.new_vaccinations,0) AS new_vaccinations, 
SUM(COALESCE(vac.new_vaccinations,0)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinations
FROM COVIDProject..CovidDeaths dea
JOIN COVIDProject..CovidVaccinations vac
ON dea.location=vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinations/Population)*100
FROM PopvsVac
ORDER BY 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(50),
Location nvarchar(50),
Date date,
Population FLOAT,
New_vaccinations FLOAT,
RollingPeopleVaccinated FLOAT
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From COVIDProject..CovidDeaths dea
Join COVIDProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for visualizations

CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From COVIDProject..CovidDeaths dea
Join COVIDProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select * 
from PercentPopulationVaccinated


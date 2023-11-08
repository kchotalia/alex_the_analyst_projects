-- Run in Azure Data Studio with Docker on MacOS

SELECT TOP(10) *
FROM dbo.CovidDeaths
WHERE new_cases > 10

SELECT TOP(10) *
FROM dbo.CovidVaccinations  

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2

-- Looking at the total cases v total deaths --
-- % shows the likelihood of death is covid is contracted --
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE [location] like '%kingdom%' -- '%states%'
ORDER BY 1,2

-- Looking at the total cases v the population --
-- Shows what % of the population has covid -- 
SELECT location, date, total_cases, population, (total_deaths/population)*100 DeathPercentage
FROM dbo.CovidDeaths
WHERE [location] like '%kingdom%' -- '%states%'
ORDER BY 1,2

-- Countries with highest infection rates c.f. population --
SELECT location, population, MAX(total_cases) as highest_infection_count,  MAX((total_cases/population))*100 as PercentInfected
FROM dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentInfected desc

-- Showing countries with the highest death count per population 
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- Break things down by continent
-- North America just USA, not including Canada BEWARE
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Showing continents with the highest death count
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- Gobal Numbers 
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths),
    SUM(new_deaths)/SUM(NULLIF(new_cases, 0))*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

SELECT TOP 10 *
FROM dbo.CovidVaccinations

-- Looking at total population v vaccinations
SELECT dea.continent, dea.[location], dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated, -- want count to start a-new at every location
    (RollingPeopleVaccinated/population)*100 -- can't use the thing we've just created
FROM dbo.CovidDeaths dea 
JOIN dbo.CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL AND dea.[location]='Albania'
ORDER BY 1,2,3


-- Use CTE --
WITH PopvVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- want count to start a-new at every location
    -- (RollingPeopleVaccinated/population)*100 -- can't use the thing we've just created
FROM dbo.CovidDeaths dea 
JOIN dbo.CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL AND dea.[location]='Albania'
-- ORDER BY 1,2,3
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvVac

-- Temp Table --
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- means you can run again and again
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC

)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- want count to start a-new at every location
FROM dbo.CovidDeaths dea 
JOIN dbo.CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL AND dea.[location]='Albania'
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualtions --
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated -- want count to start a-new at every location
FROM dbo.CovidDeaths dea 
JOIN dbo.CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.date = vac.[date]
WHERE dea.continent IS NOT NULL AND dea.[location]='Albania'
-- ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
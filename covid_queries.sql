/*
	Covid Data Exploration
*/


select *
from CovidProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from CovidProject..CovidVaccinations
--order by 3,4

-- selecting the data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from CovidProject..CovidDeaths
where continent is not null
order by 1,2

-- total cases vs total deaths - shows likelihood of dying if you got covid in Pakistan

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  as DeathPercentage
from CovidProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2

-- looking at total cases VS population - shows percentage of cases if you got covid in Pakistan

select location, date, total_cases, population, (total_cases/population)*100  as CasesPercentage
from CovidProject..CovidDeaths
--where location like 'africa'
where continent is not null
order by 1,2

-- countries with Highest Infection rate compared to population

select location, population, MAX(total_cases) as MaxInfectionRate, MAX((total_cases/population))*100  as MaxCasespercentage
from CovidProject..CovidDeaths
where continent is not null
group by location, population
order by MaxCasespercentage desc

-- showing countries with the hightest death count per population

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

select SUM(new_cases) as new_cases, SUM(cast(new_deaths as int)) as new_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as TotalDeathPercentage
from CovidProject..CovidDeaths
where continent is not null
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date,population, new_vaccinations, rollPeopleVaccinated) 
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (rollPeopleVaccinated/population)*100
from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as TotalPercentVaccinated
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Drop view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is not null
group by continent

select *
from PercentPopulationVaccinated
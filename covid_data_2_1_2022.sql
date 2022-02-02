--What we want from the dataset.
Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Shows percentage of death if you caught COVID-19 given specific date
Select Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS deathPercentage
from PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

-- Looking at total cases vs population
-- Shows percentage of population that caught COVID-19
Select Location, date, total_cases, population, (total_cases / population) * 100 AS population_to_cases_Percentage
from PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2

--What countries have the highest infection rates compares to Population
Select Location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases / population)) * 100 AS population_infected_Percentage
from PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY population_infected_Percentage desc

--Shows countries with highest death count per population.
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--Total deaths by continents.
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
WHERE continent is null AND location not like '%income%'
GROUP BY location
ORDER BY TotalDeathCount desc

-- Global numbers
SELECT date, SUM(total_cases) AS total_global_cases, SUM(cast(new_deaths as int)) as total_global_deaths, SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as Death_percentage_global
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1 desc, 2
-- We see that the percentage of death globally has dropped throughout each week.


--With that insight lets check Covid Vaccination dataset
SELECT *
FROM PortfolioProject..covidVaccinations

--JOIN BOTH TABLES
SELECT * 
FROM PortfolioProject..CovidDeaths AS deaths
JOIN PortfolioProject..covidVaccinations AS vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date

-- Looking at number of people vaccinated per day per country
SELECT deaths.location, deaths.continent, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	SUM(cast(vaccinations.new_vaccinations as bigint)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) AS sum_of_vax_perDAY
FROM PortfolioProject..CovidDeaths AS deaths
JOIN PortfolioProject..covidVaccinations AS vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
ORDER BY 1, 2, 3

--USE common table expression (CTE)
WITH VaxPerDay (Location, Continent,  Date, Population, New_Vaccinations, sum_of_vax_perDAY)
as
(
SELECT deaths.location, deaths.continent, deaths.date, deaths.population, vaccinations.new_vaccinations, 
	SUM(cast(vaccinations.new_vaccinations as bigint)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) AS sum_of_vax_perDAY
FROM PortfolioProject..CovidDeaths AS deaths
JOIN PortfolioProject..covidVaccinations AS vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
)
SELECT *, (sum_of_vax_perDAY / Population) * 100 AS Vaxxed_Population
FROM VaxPerDay
ORDER BY 1, 3

--Lets see total vaccinated by country
--We want a new col named totalVaxxed and country so we select (Location, Population, sum new vaccinations)
SELECT deaths.location, deaths.population, SUM(cast(Vaccinations.new_vaccinations as bigint)) AS Total_Vaccinated
FROM PortfolioProject..CovidDeaths AS deaths
JOIN PortfolioProject..covidVaccinations as Vaccinations
	ON deaths.location = Vaccinations.location
	AND deaths.date = Vaccinations.date
WHERE deaths.continent is not null
GROUP BY deaths.location, deaths.population
ORDER BY 1, 2

--From the results of this query we see that some countries have more total_vaccinated than population. 
--Maybe the data from total_vaccinations are the amount of vaccines they have instead of the total amount of people vaccinated?
--Theres another column named people_fully_vaccinated let see how that data relates to new_vaccinations.
SELECT deaths.location, deaths.population, MAX(cast(vaccinations.people_fully_vaccinated as bigint)) as Total_Vaxxed, 
		(MAX(cast(vaccinations.people_fully_vaccinated as bigint) / population) * 100) AS percent_Fully_Vaxxed
FROM PortfolioProject..CovidDeaths as deaths
	JOIN PortfolioProject..covidVaccinations as vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
GROUP BY deaths.location, deaths.population
ORDER BY 1,2

--Found the problem, we were originally looking at the total amount of vaccinations each country contained and not the amount of people vaccinated
-- Now we see more accurate results within the calculations.
-- Looking at the united states we get the result of 63% and comparing it to Mayoclinics results we get the same number.

--Instead of CTE lets try a temp table.

DROP Table if exists #PercentVaccinated
Create Table #PercentVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
people_fully_vaccinated numeric
)
Insert into #PercentVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.people_fully_vaccinated
FROM PortfolioProject..CovidDeaths as deaths
JOIN PortfolioProject..covidVaccinations as vaccinations
	ON deaths.location = vaccinations.location
	AND deaths.date = vaccinations.date
WHERE deaths.continent is not null

Select Location, Population, MAX(people_fully_vaccinated) AS Total_People_vaccinated,
	(Max(people_fully_vaccinated) / Population) * 100 AS Percentage_Vaccinated
FROM #PercentVaccinated
group by Location, Population
order by 1, 2


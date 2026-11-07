#-------------DATA-----------------#
SELECT location, continent, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1, 2;

# ------ Likely of death per country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 percentage_death
FROM covid_deaths
WHERE location LIKE '%Nigeria%'
ORDER BY 1, 2;

-- VIEW FOR VISUALIZATION
CREATE VIEW nigeria_death_per_infection AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 percentage_death
FROM covid_deaths
WHERE location LIKE '%Nigeria%'
ORDER BY 1, 2;

# ---------Percentage of people infected
SELECT location, date, population, total_cases, (total_cases/population)*100 percentage_infected
FROM covid_deaths
WHERE location LIKE '%Nigeria%'
ORDER BY 1, 2;


#-------Country with Highest infection count
SELECT location, population, MAX(total_cases) infection_count, MAX((total_cases/population)*100) percentage_infected
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;

#-------Country with Highest death count
SELECT location, population, MAX(total_deaths) death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;


-- DEATH BY CONTINENT
SELECT continent, MAX(total_deaths) death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

SELECT date, SUM(new_cases) t_case, SUM(new_deaths) t_death,
		(SUM(new_deaths)/SUM(new_cases))*100 percentage_death
FROM covid_deaths
GROUP BY date
ORDER BY date;


# --Population vs Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations
FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   
ORDER BY 2,3;

-- vIEWS FOR TABLEAU VISUALIZATION
CREATE VIEW populationvsvaccine AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations
FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   
ORDER BY 2,3;
;

-- ROLING VACCINATION PER DAY
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations,
		SUM(vaccine.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) roling_daily_vaccination
FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   -- location LIKE '%Nigeria%'
ORDER BY 2,3;

-- USING CTE to hold subqueries
WITH pop_vs_vac ( continent, location, date, population, new_vaccinations, rolling_daily_vaccination)
AS (
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations,
		SUM(vaccine.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) rolling_daily_vaccination
FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   -- location LIKE '%Nigeria%'
-- ORDER BY 2,3
)
SELECT *, (rolling_daily_vaccination/population) * 100 percentage_daily_vac
FROM pop_vs_vac;

-- CREATING VIEW FOR VISUALIZATION
CREATE VIEW continent_rolling_daily_vacc AS
SELECT deaths.continent, 
		deaths.location, 
        deaths.date, 
        deaths.population, 
        vaccine.new_vaccinations,
		SUM(vaccine.new_vaccinations) OVER 
        (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) rolling_daily_vaccination
FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   -- location LIKE '%Nigeria%'
-- ORDER BY 2,3
;

-- USING Temp table
DROP TEMPORARY TABLE IF EXISTS perc_popu_vaccin;

CREATE TEMPORARY TABLE perc_popu_vaccin (
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population BIGINT,
new_vaccination BIGINT,
rolling_daily_vaccination DOUBLE
);

INSERT INTO perc_popu_vaccin
SELECT deaths.continent, 
		deaths.location, 
        deaths.date, 
        deaths.population, 
        vaccine.new_vaccinations,
		SUM(vaccine.new_vaccinations) 
        OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) rolling_daily_vaccination

FROM covid_deaths deaths
JOIN covid_vaccinations vaccine
ON deaths.location = vaccine.location
	AND deaths.date = vaccine.date
WHERE deaths.continent IS NOT NULL   -- location LIKE '%Nigeria%'
-- ORDER BY 2,3
;

SELECT *, (rolling_daily_vaccination/population) * 100 percentage_daily_vac
FROM perc_popu_vaccin;
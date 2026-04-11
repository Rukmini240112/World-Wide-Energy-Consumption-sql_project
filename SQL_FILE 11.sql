CREATE DATABASE energy;
USE energy;

-- Parent table 
CREATE TABLE country_3 (
    country VARCHAR(100) PRIMARY KEY,
    cid VARCHAR(100) UNIQUE
);

CREATE TABLE consum_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption DOUBLE,
    FOREIGN KEY (country)
    REFERENCES country_3(country)
);

CREATE TABLE production_3 (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country)
    REFERENCES country_3(country)
);

CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country)
    REFERENCES country_3(country)
);

CREATE TABLE gdp_3 (
    country VARCHAR(100),
    year INT,
    value DOUBLE,
    FOREIGN KEY (country)
    REFERENCES country_3(country)
);

CREATE TABLE population_3 (
    country VARCHAR(100),
    year INT,
    val DOUBLE,
    FOREIGN KEY (country)
    REFERENCES country_3(country)
);

select * from country_3;
select * from consum_3;
select * from emission_3;
select * from gdp_3;
select * from population_3;
select * from production_3;


-- What is the total emission per country for the most recent year available?
select 
    country,
    SUM(emission) as total_emission
from emission_3
where year = (select MAX(year) from emission_3)
group by country
order by total_emission desc ;



-- What are the top 5 countries by GDP in the most recent year?
select * from gdp_3 where year=(select max(year) from gdp_3) order by value desc limit 5; 


-- Compare energy production and consumption by country and year. 
select 
    c.country,
    c.year,
    SUM(c.consumption) as total_consumption,
    SUM(p.production) as total_production
from consum_3 c
join production_3 p
    on c.country = p.country 
    and c.year = p.year
group by c.country, c.year
order by c.country, c.year;

-- Which energy types contribute most to emissions across all countries?

select energy_type,sum(emission) from emission_3 group by energy_type order by sum(energy_type) desc;

-- Trend Analysis Over Time
-- How have global emissions changed year over year?--> it's increasing 
select year,SUM(emission) AS total_emission from emission_3 group by year order by year;

-- What is the trend in GDP for each country over the given years?--> it's increasing 
select country,year,(value) from gdp_3 order by country,year;

-- How has population growth affected total emissions in each country?

select p.country,p.year,p.val as population,SUM(e.emission) as total_emission
from population_3 p
join emission_3 e
    on p.country = e.country 
   and p.year = e.year
group by p.country, p.year, p.val
order by p.country, p.year;


-- Has energy consumption increased or decreased over the years for major economies?--increased
select 
    c.country,
    c.year,
    SUM(c.consumption) AS total_consumption
from consum_3 c
join (
   select country
    from gdp_3
    where year = (select MAX(year) from gdp_3)
    order by value desc
    limit 5
) as top_countries
on c.country = top_countries.country
group by c.country, c.year
order by c.country, c.year;

-- What is the average yearly change in emissions per capita for each country?
select
    e1.country,
    avg(e1.per_capita_emission - e2.per_capita_emission) as avg_yearly_change
from emission_3 e1
join emission_3 e2
    on e1.country = e2.country 
    and e1.year = e2.year + 1
group by e1.country;
-- --> no change

-- Ratio & Per Capita Analysis
-- What is the emission-to-GDP ratio for each country by year?
select 
    e.country,
    e.year,
    SUM(e.emission) as total_emission,
    g.value as gdp,
    SUM(e.emission) / g.value AS emission_to_gdp_ratio
from emission_3 e
join gdp_3 g
    ON e.country = g.country 
    AND e.year = g.year
GROUP BY e.country, e.year, g.value
ORDER BY e.country, e.year;

-- What is the energy consumption per capita for each country over the last decade?
-- It is the total energy consumed in a country divided by its population.
select max(year) from consum_3; -- 2023
select min(year) from consum_3; -- 2020
select
    c.country,
    c.year,
    round(sum(c.consumption) / p.val, 3) AS consumption_per_capita
from consum_3 c
join population_3 p
    on c.country = p.country 
   and c.year = p.year
  -- WHERE c.year >= (SELECT MAX(year) FROM consum_3) - 9  // to get for last decade
group by c.country, c.year, p.val
ORDER BY p.country, p.year;


-- How does energy production per capita vary across countries?
select
    pr.country,
    pr.year,
    ROUND(SUM(pr.production) / pop.val, 3) AS production_per_capita
FROM production_3 pr
JOIN population_3 pop
    ON pr.country = pop.country 
    AND pr.year = pop.year
GROUP BY pr.country, pr.year, pop.val
ORDER BY pr.country, pr.year;

-- Which countries have the highest energy consumption relative to GDP?
select
    c.country,
    c.year,
    ROUND(SUM(c.consumption) / g.value, 4) as c_to_gdp_ratio
from consum_3 c
join gdp_3 g
    on c.country = g.country 
    and c.year = g.year
group by c.country, c.year, g.value
order by c_to_gdp_ratio desc;

-- What is the correlation between GDP growth and energy production growth?
select
    g.country,
    g.year,g.value,
    g.value - lag(g.value) over (PARTITION BY g.country order by g.year)as gdp_growth,
    p.total_prod - lag(p.total_prod) over (PARTITION BY p.country order by p.year) as production_growth
from gdp_3 g
join (
    select
        country,
        year,
        SUM(production) AS total_prod
    from production_3
    group by country, year
) p
on g.country = p.country and g.year = p.year;






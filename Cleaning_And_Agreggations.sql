-- Creation of the database --

CREATE DATABASE Walmart;
USE Walmart;

-- Tables Creation --

CREATE TABLE features (
id INT AUTO_INCREMENT PRIMARY KEY,
    store INT,
    date DATE,
    temperature DECIMAL (10,2),
    Fuel_Price DECIMAL(10,2),
    MarkDown1 DECIMAL (10,2),
	MarkDown2 DECIMAL (10,2),
	MarkDown3 DECIMAL (10,2),
	MarkDown4 DECIMAL (10,2),
	MarkDown5 DECIMAL (10,2),
    CPI DECIMAL (10,7),
    Unemployment DECIMAL (10,5),
    IsHoliday VARCHAR (100)
);
CREATE TABLE stores ( 
id INT AUTO_INCREMENT PRIMARY KEY, 
Store INT, 
Type CHAR(1), 
Size INT
);

CREATE TABLE test ( 
id INT AUTO_INCREMENT PRIMARY KEY, 
Store INT, 
Dept INT, 
Date DATE,
IsHoliday BOOLEAN
);

CREATE TABLE train ( 
id INT AUTO_INCREMENT PRIMARY KEY, 
Store INT, 
Dept INT, 
Date DATE,
Weekly_Sales DECIMAL (10,2),
IsHoliday BOOLEAN
);

-- Loading the csv file

LOAD DATA LOCAL INFILE '/Users/argenisibarra/Documents/Portfolio/walmart-recruiting-store-sales-forecasting/features.csv'
INTO TABLE features
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(store, @date, @temperature, @fuel_price, @markdown1, @markdown2, @markdown3, @markdown4, @markdown5, @cpi, @unemployment, @is_holiday)
SET
    date = STR_TO_DATE(@date, '%d/%m/%Y'),
    temperature = NULLIF(@temperature, 'NA'),
    fuel_price = NULLIF(@fuel_price, 'NA'),
    markdown1 = NULLIF(@markdown1, 'NA'),
    markdown2 = NULLIF(@markdown2, 'NA'),
    markdown3 = NULLIF(@markdown3, 'NA'),
    markdown4 = NULLIF(@markdown4, 'NA'),
    markdown5 = NULLIF(@markdown5, 'NA'),
    cpi = NULLIF(@cpi, 'NA'),
    unemployment = NULLIF(@unemployment, 'NA'),
    IsHoliday = NULLIF(@is_holiday, '')
    ;

-- Note: the loading was done on Mac's terminal

-- Modifying other tables like 'test' because TRUE and 'FALSE' statements work better on Varchar than BOOLEAN in this case --

ALTER TABLE Walmart.test
MODIFY COLUMN IsHoliday VARCHAR (100)
;

ALTER TABLE Walmart.train
MODIFY COLUMN IsHoliday VARCHAR (100)
;

-- Continuing to load the tables, loadind on terminal as well --

ALTER TABLE stores
DROP COLUMN id
;

ALTER TABLE stores
MODIFY COLUMN Type VARCHAR (10)
;

LOAD DATA LOCAL INFILE '/Users/argenisibarra/Documents/Portfolio/walmart-recruiting-store-sales-forecasting/stores.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r'
IGNORE 1 ROWS
(Store, Type, Size)
;

LOAD DATA LOCAL INFILE '/Users/argenisibarra/Documents/Portfolio/walmart-recruiting-store-sales-forecasting/test.csv'
INTO TABLE Walmart.test
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, Dept, @date, @IsHoliday)
SET
    Date = STR_TO_DATE(@date, '%Y-%m-%d'),
    IsHoliday = @IsHoliday
;

LOAD DATA LOCAL INFILE '/Users/argenisibarra/Documents/Portfolio/walmart-recruiting-store-sales-forecasting/train.csv'
INTO TABLE Walmart.train
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Store, Dept, @date, Weekly_Sales, @IsHoliday)
SET
    Date = STR_TO_DATE(@date, '%d/%m/%y'),
    IsHoliday = @IsHoliday
;

-- Quick check and familiarization with the data --

-- See basic info
DESCRIBE Walmart.stores;
DESCRIBE Walmart.features;
DESCRIBE Walmart.test;
DESCRIBE Walmart.train;

-- Quick counts
SELECT COUNT(*) FROM Walmart.train;
SELECT COUNT(DISTINCT Store) FROM Walmart.stores;
SELECT COUNT(*) FROM Walmart.features;
SELECT COUNT(*) FROM Walmart.test;

SELECT COUNT(DISTINCT Dept) FROM Walmart.test;
SELECT COUNT(DISTINCT Dept) FROM Walmart.train;

-- Holidays --

SELECT COUNT(DISTINCT Date) AS NumOfHolidays
FROM Walmart.train
WHERE IsHoliday LIKE '%TRUE%';

SELECT COUNT(DISTINCT Date) AS NumOfHolidays
FROM Walmart.test
WHERE IsHoliday LIKE '%TRUE%';

WITH TrainHolidays AS (
    SELECT DISTINCT Date
    FROM Walmart.train
    WHERE IsHoliday = '%TRUE%'
),
TestHolidays AS (
    SELECT DISTINCT Date
    FROM Walmart.test
    WHERE UPPER(TRIM(IsHoliday)) = 'TRUE'
)

-- LEFT JOIN part
SELECT 
    t.Date AS Date,
    CASE
        WHEN s.Date IS NOT NULL THEN 'Both'
        ELSE 'Train'
    END AS Ubicacion
FROM TrainHolidays t
LEFT JOIN TestHolidays s
    ON t.Date = s.Date

UNION

-- RIGHT JOIN part to get Test-only dates
SELECT 
    s.Date AS Date,
    'Test' AS Ubicacion
FROM TestHolidays s
LEFT JOIN TrainHolidays t
    ON s.Date = t.Date
WHERE t.Date IS NULL

ORDER BY Date;





-- Spot-check some rows
SELECT * FROM Walmart.features LIMIT 1000;
SELECT * FROM Walmart.stores LIMIT 1000;
SELECT * FROM Walmart.test LIMIT 1000;
SELECT * FROM Walmart.train LIMIT 1000;

SELECT DISTINCT Store FROM Walmart.test LIMIT 1000;
SELECT DISTINCT Store FROM Walmart.train LIMIT 1000;

-- 45 Stores, 81 Depts, 10 Holidays in train table, 3 on test table

-- Cleaning and processing of data

SELECT Store, Dept, Date, COUNT(*) 
FROM Walmart.train
GROUP BY Store, Dept, Date
HAVING COUNT(*) > 1
;

SELECT Store, Dept, Date, COUNT(*) 
FROM Walmart.test
GROUP BY Store, Dept, Date
HAVING COUNT(*) > 1
;

SELECT DISTINCT HEX(IsHoliday) AS HexValue, IsHoliday
FROM Walmart.train
;

SELECT DISTINCT HEX(IsHoliday) AS HexValue, IsHoliday
FROM Walmart.test
;


UPDATE Walmart.train
SET IsHoliday = TRIM(REPLACE(IsHoliday, '\r', ''))
;



-- Total Sales and Avg Sales per Store
SELECT Store, SUM(Weekly_Sales) AS Total_Sales
FROM Walmart.train
GROUP BY Store
ORDER BY Total_Sales DESC
LIMIT 100
;

SELECT Store, AVG(Weekly_Sales) AS AvgSales
FROM Walmart.train
GROUP BY Store
ORDER BY AvgSales DESC
;

-- Average Sales per Department
SELECT Dept, AVG(Weekly_Sales) AS AvgSales
FROM Walmart.train
GROUP BY Dept
ORDER BY AvgSales DESC
;

-- Variability per Department --

SELECT 
    Dept,
    ROUND(AVG(Weekly_Sales), 2) AS Avg_Sales,
    ROUND(STDDEV(Weekly_Sales), 2) AS Std_Deviation
FROM Walmart.train
GROUP BY Dept
ORDER BY Std_Deviation DESC
LIMIT 10
;



-- Effect of Holidays in Sales -- 
SELECT 
UPPER(TRIM(IsHoliday)) AS IsHoliday,
AVG(Weekly_Sales) AS Avg_Sales
FROM Walmart.train
GROUP BY UPPER(TRIM(IsHoliday))
ORDER BY Avg_Sales DESC
;

-- Percentual Difference --
SELECT 
    CONCAT(ROUND(
        ((Holiday.Avg_Sales - NoHoliday.Avg_Sales) / NoHoliday.Avg_Sales) * 100, 2
    ), '%') AS Diff_Percent
FROM 
    (
        SELECT AVG(Weekly_Sales) AS Avg_Sales
        FROM Walmart.train
        WHERE UPPER(TRIM(IsHoliday)) = 'TRUE'
    ) AS Holiday,
    (
        SELECT AVG(Weekly_Sales) AS Avg_Sales
        FROM Walmart.train
        WHERE UPPER(TRIM(IsHoliday)) = 'FALSE'
    ) AS NoHoliday
    ;

-- Correlation between Unemployment and Sales (AVG and 1 row per store) --

SELECT 
    t.Store,
    AVG(f.Unemployment) AS Avg_Unemployment,
    AVG(t.Weekly_Sales) AS Avg_Weekly_Sales
FROM Walmart.train t
JOIN Walmart.features f
    ON t.Store = f.Store 
    AND t.Date = f.Date
GROUP BY t.Store
ORDER BY Avg_Weekly_Sales ASC
;

-- Correlation between variables (AVG) --

SELECT 
    (AVG(f.Unemployment * t.Weekly_Sales) 
    - AVG(f.Unemployment) * AVG(t.Weekly_Sales))
    / (STD(f.Unemployment) * STD(t.Weekly_Sales)) AS corr_unemployment_sales
FROM Walmart.train t
JOIN Walmart.features f
    ON t.Store = f.Store 
    AND t.Date = f.Date
;

-- Correlation between Unemployment and Sales (Multiple weeks) --

SELECT 
    t.Store,
    f.Unemployment,
    AVG(t.Weekly_Sales) AS Avg_Weekly_Sales,
    t.Date
FROM Walmart.train t
JOIN Walmart.features f
    ON t.Store = f.Store 
    AND t.Date = f.Date
GROUP BY t.Store, f.Unemployment, t.Date
ORDER BY f.Unemployment
;

-- Correlation between variables (Multiple Weeks) --

SELECT 
    (AVG(f.Unemployment * t.Weekly_Sales) 
    - AVG(f.Unemployment) * AVG(t.Weekly_Sales))
    / (STD(f.Unemployment) * STD(t.Weekly_Sales)) AS corr_weekly
FROM Walmart.train t
JOIN Walmart.features f
    ON t.Store = f.Store 
    AND t.Date = f.Date
    ;
    
















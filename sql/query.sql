-- =====================================================================
-- HR Employee Attrition Analysis: PostgreSQL queries
-- Dataset: IBM HR Analytics Employee Attrition (1,470 employees)
-- Table:   hr_employees  (loaded from hr_attrition_clean.csv)
-- Note:    attritionflag = 1 means the employee left, 0 means stayed.
--          The average of attritionflag is the attrition rate.
-- =====================================================================

-- CONTENTS
--  1  Create table
--  2  Validation checks (row count, Yes/No counts, overall rate)
--  3  Attrition by department                         (Q1)
--  4  Attrition by overtime                           (Q2)
--  5  Attrition by job role + HAVING                  (Q1)
--  6  Attrition by income band + CASE WHEN            (Q3)
--  7  CTE: departments vs company average             (Q1)
--  8  Window function: RANK job roles                 (Q1)
--  9  Window function: RANK within department         (Q1)
-- 10  Attrition by age group                          (Q4)
-- 11  Attrition by tenure band                        (Q4)
-- 12  Attrition by job satisfaction                   (Q5)
-- 13  Attrition by work-life balance                  (Q5)
-- 14  Leavers vs stayers: average values              (Q5)
-- 15  Other factors: gender, marital status, business travel, job level, education field
-- 16  Overtime within each department
-- 17  Confounding check: income band inside each age group
-- 18  Share of all leavers by department (window SUM OVER)
-- 19  Income quartiles with NTILE
-- 20  Pay position vs department average (AVG OVER PARTITION BY)
-- 21  High-risk segment (young + new + low income)
-- 22  Top 3 job roles by attrition (filter on a window result)
-- 23  KPI summary row (matches the Power BI cards)


-- ---------------------------------------------------------------------
-- 1. CREATE TABLE
-- ---------------------------------------------------------------------
CREATE TABLE hr_employees (
    age INT,
    attrition TEXT,
    businesstravel TEXT,
    dailyrate INT,
    department TEXT,
    distancefromhome INT,
    education INT,
    educationfield TEXT,
    environmentsatisfaction INT,
    gender TEXT,
    hourlyrate INT,
    jobinvolvement INT,
    joblevel INT,
    jobrole TEXT,
    jobsatisfaction INT,
    maritalstatus TEXT,
    monthlyincome INT,
    monthlyrate INT,
    numcompaniesworked INT,
    overtime TEXT,
    percentsalaryhike INT,
    performancerating INT,
    relationshipsatisfaction INT,
    stockoptionlevel INT,
    totalworkingyears INT,
    trainingtimeslastyear INT,
    worklifebalance INT,
    yearsatcompany INT,
    yearsincurrentrole INT,
    yearssincelastpromotion INT,
    yearswithcurrmanager INT,
    attritionflag INT,
    agegroup TEXT,
    incomelevel TEXT,
    tenureband TEXT
);


-- ---------------------------------------------------------------------
-- 2. VALIDATION CHECKS (after importing the CSV)
-- ---------------------------------------------------------------------
-- Expected: 1470 rows
SELECT COUNT(*) AS total_employees FROM hr_employees;

-- Expected: No = 1233, Yes = 237
SELECT attrition, COUNT(*) AS employees
FROM hr_employees
GROUP BY attrition;

-- Overall attrition rate. Expected: 16.1
SELECT ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS overall_attrition_rate
FROM hr_employees;


-- ---------------------------------------------------------------------
-- 3. ATTRITION BY DEPARTMENT (Question 1)
-- GROUP BY splits employees into groups; SUM(attritionflag) counts leavers.
-- ---------------------------------------------------------------------
SELECT
    department,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY department
ORDER BY attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 4. ATTRITION BY OVERTIME (Question 2)
-- ---------------------------------------------------------------------
SELECT
    overtime,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY overtime
ORDER BY attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 5. ATTRITION BY JOB ROLE, ONLY GROUPS WITH 50+ EMPLOYEES (Question 1)
-- WHERE filters rows before grouping; HAVING filters groups after grouping.
-- ---------------------------------------------------------------------
SELECT
    jobrole,
    COUNT(*) AS employees,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY jobrole
HAVING COUNT(*) >= 50
ORDER BY attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 6. ATTRITION BY INCOME BAND USING CASE WHEN (Question 3)
-- Expected: Low 28.6, Medium 12.7, High 12.0, Very High 8.9
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN monthlyincome <= 3000 THEN 'Low'
        WHEN monthlyincome <= 6000 THEN 'Medium'
        WHEN monthlyincome <= 10000 THEN 'High'
        ELSE 'Very High'
    END AS income_band,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY income_band
ORDER BY MIN(monthlyincome);


-- ---------------------------------------------------------------------
-- 7. CTE: EACH DEPARTMENT COMPARED WITH THE COMPANY AVERAGE
-- ---------------------------------------------------------------------
WITH dept AS (
    SELECT
        department,
        COUNT(*) AS employees,
        ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
    FROM hr_employees
    GROUP BY department
),
overall AS (
    SELECT ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS company_rate
    FROM hr_employees
)
SELECT
    d.department,
    d.employees,
    d.attrition_rate,
    o.company_rate,
    ROUND(d.attrition_rate - o.company_rate, 1) AS diff_vs_company
FROM dept d
CROSS JOIN overall o
ORDER BY d.attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 8. WINDOW FUNCTION: RANK JOB ROLES BY ATTRITION RATE
-- ---------------------------------------------------------------------
WITH role AS (
    SELECT
        jobrole,
        COUNT(*) AS employees,
        ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
    FROM hr_employees
    GROUP BY jobrole
)
SELECT
    jobrole,
    employees,
    attrition_rate,
    RANK() OVER (ORDER BY attrition_rate DESC) AS rank_no
FROM role;


-- ---------------------------------------------------------------------
-- 9. WINDOW FUNCTION WITH PARTITION BY: RANK JOB ROLES WITHIN EACH DEPARTMENT
-- ---------------------------------------------------------------------
WITH role AS (
    SELECT
        department,
        jobrole,
        COUNT(*) AS employees,
        ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
    FROM hr_employees
    GROUP BY department, jobrole
)
SELECT
    department,
    jobrole,
    employees,
    attrition_rate,
    RANK() OVER (PARTITION BY department ORDER BY attrition_rate DESC) AS rank_in_dept
FROM role
ORDER BY department, rank_in_dept;


-- ---------------------------------------------------------------------
-- 10. ATTRITION BY AGE GROUP (Question 4)
-- Expected: 18-25 35.8, 26-35 19.1, 36-45 9.2, 46-55 11.5, 56+ 17.0
-- ORDER BY MIN(age) keeps the groups in age order, not alphabetical order.
-- ---------------------------------------------------------------------
SELECT
    agegroup,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY agegroup
ORDER BY MIN(age);


-- ---------------------------------------------------------------------
-- 11. ATTRITION BY TENURE BAND (Question 4)
-- Expected: 0-2 yrs 29.8, 3-5 yrs 13.8, 6-10 yrs 12.3, 11+ yrs 8.1
-- ---------------------------------------------------------------------
SELECT
    tenureband,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY tenureband
ORDER BY MIN(yearsatcompany);


-- ---------------------------------------------------------------------
-- 12. ATTRITION BY JOB SATISFACTION (Question 5)
-- Scale: 1 = Low, 2 = Medium, 3 = High, 4 = Very High
-- ---------------------------------------------------------------------
SELECT
    jobsatisfaction,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY jobsatisfaction
ORDER BY jobsatisfaction;


-- ---------------------------------------------------------------------
-- 13. ATTRITION BY WORK-LIFE BALANCE (Question 5)
-- ---------------------------------------------------------------------
SELECT
    worklifebalance,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY worklifebalance
ORDER BY worklifebalance;


-- ---------------------------------------------------------------------
-- 14. LEAVERS VS STAYERS: AVERAGE VALUES (Question 5)
-- Expected (Yes row): satisfaction 2.47, work-life 2.66, years since
-- promotion 1.95, income 4787.09, distance 10.63
-- ---------------------------------------------------------------------
SELECT
    attrition,
    ROUND(AVG(jobsatisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(worklifebalance), 2) AS avg_work_life_balance,
    ROUND(AVG(yearssincelastpromotion), 2) AS avg_years_since_promotion,
    ROUND(AVG(monthlyincome), 2) AS avg_monthly_income,
    ROUND(AVG(distancefromhome), 2) AS avg_distance_from_home
FROM hr_employees
GROUP BY attrition;


-- ---------------------------------------------------------------------
-- 15. OTHER FACTORS (extra exploration)
-- Each query uses the same pattern: group, count, sum the flag, divide.
-- ---------------------------------------------------------------------
-- 15a. Gender
SELECT
    gender,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY gender
ORDER BY attrition_rate DESC;

-- 15b. Marital status
SELECT
    maritalstatus,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY maritalstatus
ORDER BY attrition_rate DESC;

-- 15c. Business travel
SELECT
    businesstravel,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY businesstravel
ORDER BY attrition_rate DESC;

-- 15d. Job level (1 = entry level, 5 = senior)
SELECT
    joblevel,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY joblevel
ORDER BY joblevel;

-- 15e. Education field
SELECT
    educationfield,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY educationfield
ORDER BY attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 16. OVERTIME WITHIN EACH DEPARTMENT
-- Grouping by two columns shows whether the overtime effect is the same
-- in every department.
-- ---------------------------------------------------------------------
SELECT
    department,
    overtime,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM hr_employees
GROUP BY department, overtime
ORDER BY department, overtime;


-- ---------------------------------------------------------------------
-- 17. CONFOUNDING CHECK: INCOME BAND INSIDE EACH AGE GROUP
-- Age, income and tenure overlap. If low income still has higher attrition
-- inside every age group, income matters on its own. HAVING hides tiny groups.
-- ---------------------------------------------------------------------
WITH base AS (
    SELECT
        agegroup,
        age,
        attritionflag,
        CASE
            WHEN monthlyincome <= 3000 THEN 1
            WHEN monthlyincome <= 6000 THEN 2
            WHEN monthlyincome <= 10000 THEN 3
            ELSE 4
        END AS band_no,
        CASE
            WHEN monthlyincome <= 3000 THEN 'Low'
            WHEN monthlyincome <= 6000 THEN 'Medium'
            WHEN monthlyincome <= 10000 THEN 'High'
            ELSE 'Very High'
        END AS income_band
    FROM hr_employees
)
SELECT
    agegroup,
    income_band,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM base
GROUP BY agegroup, band_no, income_band
HAVING COUNT(*) >= 20
ORDER BY MIN(age), band_no;


-- ---------------------------------------------------------------------
-- 18. SHARE OF ALL LEAVERS BY DEPARTMENT (window function over the groups)
-- A department can have the lowest RATE but the most leavers because it is
-- the biggest. Rates and counts answer different questions.
-- ---------------------------------------------------------------------
SELECT
    department,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / SUM(SUM(attritionflag)) OVER (), 1) AS pct_of_all_leavers
FROM hr_employees
GROUP BY department
ORDER BY left_count DESC;


-- ---------------------------------------------------------------------
-- 19. INCOME QUARTILES WITH NTILE
-- NTILE(4) splits employees into 4 equal-sized groups by income.
-- ---------------------------------------------------------------------
WITH q AS (
    SELECT
        attritionflag,
        monthlyincome,
        NTILE(4) OVER (ORDER BY monthlyincome) AS income_quartile
    FROM hr_employees
)
SELECT
    income_quartile,
    MIN(monthlyincome) AS min_income,
    MAX(monthlyincome) AS max_income,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM q
GROUP BY income_quartile
ORDER BY income_quartile;


-- ---------------------------------------------------------------------
-- 20. PAY POSITION VS DEPARTMENT AVERAGE
-- AVG() OVER (PARTITION BY department) puts the department average on every
-- employee row, so each person can be compared with their own department.
-- ---------------------------------------------------------------------
WITH x AS (
    SELECT
        attritionflag,
        monthlyincome,
        AVG(monthlyincome) OVER (PARTITION BY department) AS dept_avg_income
    FROM hr_employees
)
SELECT
    CASE
        WHEN monthlyincome < dept_avg_income THEN 'Below department average'
        ELSE 'At or above department average'
    END AS pay_position,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM x
GROUP BY pay_position
ORDER BY pay_position;


-- ---------------------------------------------------------------------
-- 21. HIGH-RISK SEGMENT: YOUNG + NEW + LOW INCOME
-- Check the employee count before quoting the rate (small groups are unstable).
-- ---------------------------------------------------------------------
WITH seg AS (
    SELECT
        attritionflag,
        CASE
            WHEN age <= 25 AND yearsatcompany <= 2 AND monthlyincome <= 3000
                THEN 'Age 25 or under, 0-2 yrs, low income'
            ELSE 'Everyone else'
        END AS segment
    FROM hr_employees
)
SELECT
    segment,
    COUNT(*) AS employees,
    SUM(attritionflag) AS left_count,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
FROM seg
GROUP BY segment
ORDER BY attrition_rate DESC;


-- ---------------------------------------------------------------------
-- 22. TOP 3 JOB ROLES BY ATTRITION RATE
-- A window function cannot be used in WHERE directly, so rank in a CTE
-- first and filter in the outer query.
-- ---------------------------------------------------------------------
WITH role AS (
    SELECT
        jobrole,
        COUNT(*) AS employees,
        ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate
    FROM hr_employees
    GROUP BY jobrole
),
ranked AS (
    SELECT
        jobrole,
        employees,
        attrition_rate,
        RANK() OVER (ORDER BY attrition_rate DESC) AS rank_no
    FROM role
)
SELECT jobrole, employees, attrition_rate, rank_no
FROM ranked
WHERE rank_no <= 3
ORDER BY rank_no;


-- ---------------------------------------------------------------------
-- 23. KPI SUMMARY ROW (should match your Power BI KPI cards)
-- Expected: 1470 employees, 237 left, 16.1 attrition rate
-- ---------------------------------------------------------------------
SELECT
    COUNT(*) AS total_employees,
    SUM(attritionflag) AS employees_left,
    ROUND(100.0 * SUM(attritionflag) / COUNT(*), 1) AS attrition_rate,
    ROUND(AVG(monthlyincome), 0) AS avg_monthly_income,
    ROUND(AVG(yearsatcompany), 1) AS avg_years_at_company
FROM hr_employees;

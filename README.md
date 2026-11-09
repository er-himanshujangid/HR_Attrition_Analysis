# HR Employee Attrition Analysis

An end-to-end data analysis project that finds **which employees leave a company and which factors are linked to it**, using Python, Excel, PostgreSQL, and Power BI.

![Dashboard](dashboard/dashboard_screenshot.png)

## Business Problem

A company loses employees every year, and replacing them is expensive. HR wants to know **who is leaving and what factors are linked to attrition**, so it can focus its retention efforts where they matter most.

## Dataset

- **Source:** IBM HR Analytics Employee Attrition & Performance (Kaggle)
- **Size:** 1,470 employees, 35 columns (one row per employee)
- **Target column:** `Attrition` (Yes = left, No = stayed)
- **Note:** this is a widely used practice dataset, so the findings are for learning, not real company advice.

## Tools Used

| Tool | Used for |
|---|---|
| Python (Pandas, NumPy, Matplotlib, Seaborn) | Validation, preparation, exploratory analysis |
| Excel | First look at the data, PivotTable cross-check |
| PostgreSQL | Storing the data and answering business questions with SQL |
| Power BI | Interactive dashboard (DAX measures, KPI cards, charts, slicers) |

## Workflow

1. **Setup:** project folders, dataset download, first look in Excel.
2. **Validation (Python):** checked shape, missing values, duplicates, and constant columns. Result: 0 missing values, 0 duplicates, and 3 columns with a single value.
3. **Preparation (Python):** dropped 4 uninformative columns (`EmployeeCount`, `StandardHours`, `Over18`, `EmployeeNumber`), converted `Attrition` to a 1/0 flag, and created age, income, and tenure groups.
4. **Exploratory Data Analysis:** compared attrition **rates** (not raw counts) across departments, overtime, age groups, income levels, tenure, and satisfaction scores.
5. **Excel cross-check:** rebuilt the department attrition rates with a PivotTable. The results matched Python.
6. **SQL (PostgreSQL):** loaded the data and answered the same questions with `GROUP BY`, `HAVING`, `CASE WHEN`, CTEs, and window functions (`RANK`, `PARTITION BY`, `NTILE`).
7. **Dashboard (Power BI):** connected to PostgreSQL and built DAX measures, KPI cards, five charts, and four slicers.

All key numbers (for example the overall attrition rate of 16.1%) were checked across Python, Excel, SQL, and Power BI.

## Key Findings

- **Overall attrition is 16.1%** (237 of 1,470 employees left).
- **Overtime:** employees working overtime leave at about **30.5%**, compared with about **10.4%** for those who do not (roughly 3 times higher).
- **Age:** attrition is highest for ages **18-25 (35.8%)** and lowest for 36-45 (9.2%).
- **Tenure:** employees in their **first two years leave at 29.8%**, compared with 8.1% for those with 11+ years.
- **Income:** **low-income** employees leave at **28.6%**, compared with 8.9% for the highest earners.
- **Department:** Sales (20.6%) and Human Resources (19.0%) are above the company average, while Research & Development (13.8%) is below.
- Leavers earn about 30% less on average and report lower job satisfaction (2.47 vs 2.78).
- Years since last promotion did **not** explain attrition: leavers actually had slightly fewer years since promotion (1.95 vs 2.23).

## Recommendations

- Strengthen onboarding and mentoring during the first two years.
- Review pay for the low-income band.
- Review overtime workload, especially for new and young employees.
- Look into why Sales and HR lose a higher share of employees (for example, with exit interviews).

## Limitations

- **Correlation is not causation:** the analysis shows links, not causes.
- **Overlapping factors:** young employees are often newer and paid less, so age, tenure, and income may reflect the same underlying group.
- **Small groups:** for example, the 56+ age group has only 47 employees, so its rate is less reliable.
- **Single snapshot:** the data has no dates, so trends over time cannot be analysed.

## Project Structure

```
HR_Attrition_Analysis/
├── data/          raw and prepared datasets
├── notebooks/     Jupyter notebooks (validation, preparation, EDA)
├── sql/           hr_attrition_queries.sql (23 sections)
├── dashboard/     Power BI file and screenshots
└── README.md
```

## How to Reproduce

1. Download the dataset from Kaggle and place it in `data/`.
2. Run the notebooks in order to validate and prepare the data and save `hr_attrition_clean.csv`.
3. In PostgreSQL, create a database `hr_attrition`, then run the table creation script from `sql/hr_attrition_queries.sql` and import `hr_attrition_clean.csv` into the `hr_employees` table.
4. Open the Power BI file in `dashboard/` and refresh the PostgreSQL connection.

## Author

**Himanshu**: aspiring Data Analyst
[LinkedIn](https://linkedin.com/in/himanshu-02a28b254) | [GitHub](https://github.com/er-himanshujangid)

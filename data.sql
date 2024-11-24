WITH cte_managers AS (SELECT DISTINCT 
                          ManagerID
                      FROM tc-da-1.adwentureworks_db.employee),
     cte_latest_address AS (SELECT
                                EmployeeID,
                                MAX(AddressID) AS AddressID
                            FROM tc-da-1.adwentureworks_db.employeeaddress
                            GROUP BY EmployeeID),
     cte_latest_pay_date AS (SELECT
                                EmployeeID,
                                MAX(RateChangeDate) AS LatestPayDate
                             FROM tc-da-1.adwentureworks_db.employeepayhistory
                             GROUP BY EmployeeID),
     cte_hourly_pay AS (SELECT 
                            eph.EmployeeID,
                            ROUND(eph.Rate,2) AS HourlyPay
                        FROM tc-da-1.adwentureworks_db.employeepayhistory eph
                            JOIN cte_latest_pay_date cte_lpd
                                ON eph.EmployeeID = cte_lpd.EmployeeID AND eph.RateChangeDate = cte_lpd.LatestPayDate),
     cte_age AS (SELECT
                     EmployeeId,
                     CAST(FLOOR(DATE_DIFF(CAST('2005-11-30' AS DATE),BirthDate, DAY)/365) AS INT64) AS Age
                 FROM tc-da-1.adwentureworks_db.employee)

SELECT
    (emp.EmployeeId + 159) AS ID,
    emp.Title,
    age.Age,
    CASE
        WHEN age.Age BETWEEN 0 AND 25 THEN 'Up to 25 years old'
        WHEN age.Age BETWEEN 26 AND 35 THEN '26-35 years old'
        WHEN age.Age BETWEEN 36 AND 50 THEN '36-50 years old'
        ELSE '50+ years old'
        END AS AgeGroup,
    CASE emp.Gender
        WHEN 'M' THEN 'Male'
        ELSE 'Female'
        END AS Gender,
    CASE emp.MaritalStatus
        WHEN 'S' THEN 'Single'
        ELSE 'Married'
        END AS MaritalStatus,
    CASE WHEN (UPPER(emp.Title) LIKE '%CHIEF%' OR UPPER(emp.Title) LIKE '%VICE PRESIDENT%') AND UPPER(emp.Title) NOT LIKE '%ASSISTANT%' THEN "Top manager"
         WHEN man.ManagerID IS NULL THEN 'Not manager'
         ELSE 'Manager'
         END AS IsManager,
    dept.Name AS Department,
    country.CountryRegionCode AS CountryCode,
    country.Name AS Country,
    pay.HourlyPay,
    CONCAT(ROUND(pay.HourlyPay,-1),'-',ROUND(pay.HourlyPay,-1)+9) AS HourlyPayRange
FROM tc-da-1.adwentureworks_db.employee emp
    LEFT JOIN cte_managers man
        ON emp.EmployeeId = man.ManagerID
    LEFT JOIN tc-da-1.adwentureworks_db.employeedepartmenthistory dept_hist
        ON emp.EmployeeId = dept_hist.EmployeeID AND dept_hist.EndDate IS NULL
    LEFT JOIN tc-da-1.adwentureworks_db.department dept
        ON dept_hist.DepartmentID = dept.DepartmentID
    LEFT JOIN cte_latest_address
        ON emp.EmployeeId = cte_latest_address.EmployeeID
    LEFT JOIN tc-da-1.adwentureworks_db.address addr
        ON cte_latest_address.AddressID = addr.AddressID
    LEFT JOIN tc-da-1.adwentureworks_db.stateprovince state
        ON addr.StateProvinceID = state.StateProvinceID
    LEFT JOIN tc-da-1.adwentureworks_db.countryregion country
        ON state.CountryRegionCode = country.CountryRegionCode
    LEFT JOIN cte_hourly_pay pay
        ON emp.EmployeeId = pay.EmployeeID
    LEFT JOIN cte_age age
        ON emp.EmployeeId = age.EmployeeId
ORDER BY emp.EmployeeId
SELECT * FROM healthinsurance.enhanced_health_insurance_claims;

-- Cleaning
CREATE TABLE claims_cleaned AS
SELECT
    ClaimID,
    PatientID,
    ProviderID,
    ClaimAmount,
    ClaimDate,
    YEAR(ClaimDate) AS ClaimYear,
    MONTH(ClaimDate) AS ClaimMonth,
    DiagnosisCode,
    ProcedureCode,
    PatientAge,
    PatientGender,
    ProviderSpecialty,
    UPPER(ClaimStatus) AS ClaimStatus,
    PatientIncome,
    PatientMaritalStatus,
    PatientEmploymentStatus,
    ProviderLocation,
    ClaimType,
    ClaimSubmissionMethod,
    CASE 
        WHEN ClaimAmount > 10000 THEN 1
        ELSE 0
    END AS IsHighCost,
    CASE 
        WHEN PatientAge < 18 THEN '0-17'
        WHEN PatientAge BETWEEN 18 AND 35 THEN '18-35'
        WHEN PatientAge BETWEEN 36 AND 60 THEN '36-60'
        ELSE '60+'
    END AS AgeGroup
FROM enhanced_health_insurance_claims;

--  Monthly Cost & Volume Trends
 SELECT 
    ClaimYear, ClaimMonth,
    COUNT(*) AS TotalClaims,
    ROUND(SUM(ClaimAmount), 2) AS TotalCost,
    ROUND(AVG(ClaimAmount), 2) AS AvgClaimCost
FROM claims_cleaned
GROUP BY ClaimYear, ClaimMonth
ORDER BY ClaimYear, ClaimMonth;

-- Approval Rate by Claim Status
SELECT 
    ClaimStatus,
    COUNT(*) AS ClaimCount,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM claims_cleaned), 2) AS Percentage
FROM claims_cleaned
GROUP BY ClaimStatus;

-- High-Cost Claims by Provider Specialty
SELECT 
    ProviderSpecialty,
    COUNT(*) AS TotalClaims,
    SUM(CASE WHEN IsHighCost = 1 THEN 1 ELSE 0 END) AS HighCostClaims,
    ROUND(SUM(ClaimAmount), 2) AS TotalCost
FROM claims_cleaned
GROUP BY ProviderSpecialty
ORDER BY TotalCost DESC;

--  Cost per Member per Month (PMPM)

SELECT 
    ClaimYear,
    ClaimMonth,
    COUNT(DISTINCT PatientID) AS UniqueMembers,
    ROUND(SUM(ClaimAmount), 2) AS TotalCost,
    ROUND(SUM(ClaimAmount) / COUNT(DISTINCT PatientID), 2) AS PMPM
FROM claims_cleaned
GROUP BY ClaimYear, ClaimMonth
ORDER BY ClaimYear, ClaimMonth;

-- Emergency vs Inpatient vs Routine Cost Impact

SELECT 
    ClaimType,
    COUNT(*) AS NumClaims,
    ROUND(SUM(ClaimAmount), 2) AS TotalCost,
    ROUND(AVG(ClaimAmount), 2) AS AvgClaimCost
FROM claims_cleaned
GROUP BY ClaimType
ORDER BY TotalCost DESC;

-- Provider Specialty Efficiency
SELECT 
    ProviderSpecialty,
    COUNT(*) AS ClaimCount,
    ROUND(SUM(ClaimAmount), 2) AS TotalCost,
    ROUND(AVG(ClaimAmount), 2) AS AvgClaim,
    ROUND(SUM(ClaimAmount) / COUNT(DISTINCT PatientID), 2) AS CostPerMember
FROM claims_cleaned
GROUP BY ProviderSpecialty
ORDER BY TotalCost DESC;

-- Claim Approval vs Rejection Cost Analysis

SELECT 
    ClaimStatus,
    COUNT(*) AS NumClaims,
    ROUND(SUM(ClaimAmount), 2) AS TotalClaimValue,
    ROUND(AVG(ClaimAmount), 2) AS AvgClaimValue
FROM claims_cleaned
GROUP BY ClaimStatus
ORDER BY TotalClaimValue DESC;

-- Time Trend Deviation: Month-over-Month Cost Change

WITH monthly_totals AS (
    SELECT 
        ClaimYear,
        ClaimMonth,
        ROUND(SUM(ClaimAmount), 2) AS TotalCost
    FROM claims_cleaned
    GROUP BY ClaimYear, ClaimMonth
),
month_diff AS (
    SELECT 
        a.ClaimYear,
        a.ClaimMonth,
        a.TotalCost,
        a.TotalCost - b.TotalCost AS CostChange,
        ROUND(100 * (a.TotalCost - b.TotalCost) / b.TotalCost, 2) AS PercentChange
    FROM monthly_totals a
    JOIN monthly_totals b
      ON a.ClaimYear = b.ClaimYear AND a.ClaimMonth = b.ClaimMonth + 1
)
SELECT * FROM month_diff;


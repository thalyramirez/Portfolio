/*This project 🚀 analyzed the H1-B visa application process to empower stakeholders with data-driven insights for strategic workforce planning and policy evaluation.
By transforming raw public data into actionable findings through SQL, Power Query, and advanced analytics,
the project provided a comprehensive overview of hiring trends and success probabilities within the U.S. immigration system.
*/

USE h1b_visa;
 
#states with more certified sponsorship opportunities AND salaries
SELECT WORKSITE_STATE, COUNT(*) as sponsored_visa, AVG(PREVAILING_WAGE) as avg_wage
FROM h1b_view
GROUP BY WORKSITE_STATE
ORDER BY sponsored_visa DESC, avg_wage DESC
LIMIT 10;
 
#Ocuppations with more sponsorships' opportunites in the  state (1) with the highest number of certified sponsorships 
SELECT COUNT(*) AS  N_cases, SOC_TITLE
FROM h1b_view
WHERE WORKSITE_STATE =  (SELECT WORKSITE_STATE FROM (SELECT  COUNT(*) as job_ocuppation, WORKSITE_STATE
FROM h1b_view
GROUP BY WORKSITE_STATE
ORDER BY job_ocuppation DESC
LIMIT 1) AS state)
GROUP BY SOC_TITLE
ORDER BY N_cases DESC
;
 
#||Which functions seem to pay the most? ||
SELECT SOC_TITLE, AVG(PREVAILING_WAGE) AS AVG_WAGE FROM h1b_view
GROUP BY SOC_TITLE
ORDER BY AVG_WAGE DESC
LIMIT 5;
 
#||Are there certain types of jobs concentrated in certain geographical areas?||
#JOBS CONCENTRATED IN states in West coast (because there we can found the most relevant states MA and CA). 
SELECT COUNT(*) AS  N_cases, SOC_TITLE
FROM h1b_view
WHERE WORKSITE_STATE IN('WA', 'CA', 'OR','AR','WY','NM','NV','UT','CO','ID','MT')
GROUP BY SOC_TITLE
ORDER BY N_cases DESC
;
 
 
#Industries with more sponsorship oportunities with a salary higher than the average paid to the TOP 5 jobs best paid
#As Error Code: 1235. This version of MySQL doesn't yet support 'LIMIT & IN/ALL/ANY/SOME subquery'	, a hard-code had to be done in order to get the results.
SELECT 
    COUNT(PREVAILING_WAGE) AS N_WAGES, NAICS_CODE
FROM
    (SELECT 
        SOC_TITLE, NAICS_CODE, PREVAILING_WAGE
    FROM
        h1b_view
    ORDER BY PREVAILING_WAGE DESC) AS SOC_NAICS
WHERE
    SOC_TITLE IN ('Computer and Information Systems Managers' , 'Occupational Health and Safety Specialists',
        'Lawyers',
        'Sales Engineers',
        'Business Intelligence Analysts')
        AND PREVAILING_WAGE > (SELECT 
            AVG(AVG_WAGE)
        FROM
            (SELECT 
                SOC_TITLE, AVG(PREVAILING_WAGE) AS AVG_WAGE
            FROM
                h1b_view
            GROUP BY SOC_TITLE
            ORDER BY AVG_WAGE DESC
            LIMIT 5) AS GEN_WAGE)
GROUP BY NAICS_CODE
ORDER BY N_WAGES DESC
LIMIT 5;
#Query that showed the results of the hard-code (WHERE SOC_TITLE IN(...))
/*SELECT SOC_TITLE, AVG(PREVAILING_WAGE) AS AVG_WAGE FROM h1b_view
GROUP BY SOC_TITLE
ORDER BY AVG_WAGE DESC
LIMIT 5;*/
 
#||Which are the top employers in a certain state in a certain industry?||
SELECT employer_name, count(*) as certifications, avg(PREVAILING_WAGE) as avg_wage FROM h1b_view
where WORKSITE_STATE = "WA" and NAICS_CODE =45411
GROUP BY employer_name
ORDER BY certifications DESC, avg_wage DESC;
 
#||Are there outliers in the salary data?||
#Salaries by state that are 50% lower than the states' average 
SELECT 
    h1.WORKSITE_STATE, COUNT(*) AS N_WAGES
FROM
    h1b_view AS h1
        INNER JOIN
    (SELECT 
        WORKSITE_STATE,
            ACCEPTED_DIFF,
            AVG_W,
            MIN_W,
            MAX_W,
            (AVG_W - MIN_W) / AVG_W AS MIN_DIFF_FROM_AVG
    FROM
        (SELECT 
        WORKSITE_STATE,
            AVG(PREVAILING_WAGE) * (1 - 0.5) AS ACCEPTED_DIFF,
            AVG(PREVAILING_WAGE) AS AVG_W,
            MIN(PREVAILING_WAGE) AS MIN_W,
            MAX(PREVAILING_WAGE) AS MAX_W
    FROM
        h1b_view
    GROUP BY WORKSITE_STATE) AS WAGE_OUTLIERS
    GROUP BY WORKSITE_STATE
    ORDER BY MIN_DIFF_FROM_AVG DESC) AS ine ON ine.WORKSITE_STATE = h1.WORKSITE_STATE
WHERE
    h1.PREVAILING_WAGE <= ine.ACCEPTED_DIFF
GROUP BY ine.WORKSITE_STATE
ORDER BY N_WAGES DESC
limit 5;

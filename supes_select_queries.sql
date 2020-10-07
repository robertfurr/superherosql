----------------------------------------
-- TIP #2 - WHERE 1=0
----------------------------------------
SELECT
    s.name
    , s.creator
    -- oops
    , s.intelligance
    --, s.intelligence
FROM supes s
WHERE 1=0  
;
----------------------------------------
-- TIP #3 - WHERE 1=1 , AND …
----------------------------------------
SELECT
    s.*
FROM supes s
WHERE 1=1
    --AND s.intelligence >= 60
    --AND s.name like 'P%'
    --AND s.fullname IS NOT NULL
    --AND s.alignment = 'good'
    --AND s.gender = 'F'
    --AND s.strength = 100
    --AND s.creator = 'Marvel'
;
----------------------------------------
-- TIP #4 - Aliased Subqueries
----------------------------------------
SELECT
    marvel_supes.*
FROM
    (
    SELECT
        s.*
    FROM supes s
    WHERE 1=1
        AND s.creator = 'Marvel'
    ) marvel_supes
INNER JOIN
    (
    SELECT
        s.*
    FROM supes s
    WHERE 1=1
        AND s.alignment = 'good'
        AND s.fullname like '%o%'
        AND s.gender = 'M'
    ) good_o_supes
ON good_o_supes.supeid = marvel_supes.supeid
;
----------------------------------------
-- TIP #5 - Fake your Data
----------------------------------------
SELECT *
FROM
    (
    SELECT 'Deadpool' AS NAME, 'Swords' AS WEAPON, 'Ryan Reynolds' AS ACTOR FROM DUAL UNION ALL
    SELECT 'Batman' AS NAME, 'Batarang' as WEAPON, 'Michael Keaton' AS ACTOR FROM  DUAL UNION ALL
    SELECT 'Wolverine' AS NAME, 'Claws' AS WEAPON, 'Hugh Jackman' AS ACTOR FROM DUAL
    ) myfaves
INNER JOIN supes s ON myfaves.name = s.name
;
----------------------------------------
-- TIP #6 - WITH / CTE
----------------------------------------
WITH theboys
AS
    (
    SELECT 'Homelander' AS NAME, 'The Boys' AS creator, 'bad' AS alignment, 'M' as gender FROM DUAL UNION ALL
    SELECT 'Maeve' AS NAME, 'The Boys' AS creator, 'good' AS alignment, 'F' as gender FROM  DUAL UNION ALL
    SELECT 'Starlight' AS NAME, 'The Boys' AS creator, 'good' AS alignment, 'F' as gender FROM DUAL
    )
, dc_good
AS
    (
    SELECT * FROM supes sdc
    WHERE 1=1
        AND sdc.creator = 'DC'
        AND sdc.alignment = 'good'
    )
-- Q1 - get the boys
SELECT 'Q1' as query, b.* FROM theboys b
UNION ALL
-- Q2 - get the Marvel top 3
SELECT 'Q2' as query, s.name, s.creator, s.alignment, s.gender FROM supes s WHERE s.creator = 'Marvel' AND ROWNUM < 4
UNION ALL
-- Q3 - get the good boys
SELECT 'Q3' as query, dc.name, dc.creator, dc.alignment, dc.gender FROM dc_good dc WHERE dc.gender = 'M' AND ROWNUM < 4
UNION ALL
-- Q4 - get the DC good girls
SELECT 'Q4' as query, dc.name, dc.creator, dc.alignment, dc.gender FROM dc_good dc WHERE dc.gender = 'F' AND ROWNUM < 4



;
----------------------------------------
-- TIP #7 - (Antipattern) Don’t use DISTINCT
----------------------------------------
SELECT 'Distinct Cnt' AS query, COUNT(*) as cnt
FROM
    (
    SELECT DISTINCT s.* FROM supes s
    )
UNION ALL
SELECT 'Total Cnt' AS query, COUNT(*) as cnt FROM supes ss
;
----------------------------------------
-- TIP #8 - COALESCE, DECODE, IsNull/NVL, and NullIf
----------------------------------------
UPDATE supes SET speed = 0 WHERE speed IS NULL;

SELECT 
    s.name
    , s.power as power_orig
    , COALESCE(s.power, 50) as power
    , s.speed
    -- Oops - divide by zero error
    --, COALESCE(s.power, 50) / s.speed as power_speed_ratio
    -- Alternatives
    --, COALESCE(s.power, 50) / decode(s.speed,0,null) as power_speed_ratio_v1
    --, COALESCE(s.power, 50) / decode(s.speed,0,1) as power_speed_ratio_v2
FROM supes s 
WHERE
    s.speed = 0
;
----------------------------------------
-- TIP #9 - CASE
----------------------------------------
SELECT 
    s.name
    , s.alignment
    , (CASE
        WHEN s.name = 'Riddler' THEN 'My Fave'
        WHEN s.alignment = 'good' THEN 'Goody2Shoes'
        WHEN s.alignment = 'bad' THEN 'BadBadBaddie'
        ELSE 'Unknown'
    END) AS good_or_bad
FROM supes s 
WHERE
    1 = (CASE
        WHEN s.name LIKE 'Ri%' THEN 1
        WHEN s.gender = 'F' AND s.name like 'B%W%' THEN 1
        ELSE 0
        END)
;
----------------------------------------
-- TIP #10 - Window Functions
----------------------------------------
WITH supes_with_tot AS
    (
    SELECT ss.*, ss.intelligence + ss.strength + ss.speed + ss.power + ss.combat as total_power from supes ss
    )

SELECT 
    s.name, s.creator, s.alignment, s.gender
    , s.total_power
    , RANK() OVER(ORDER BY s.total_power DESC NULLS LAST) as rank_overall_by_total_power
    , RANK() OVER(PARTITION BY s.creator ORDER BY s.total_power DESC NULLS LAST) as rank_in_universe_by_total_power
    , COUNT(*) OVER(PARTITION BY s.creator) as cnt_creator
    , ROUND(s.total_power / SUM(s.total_power) OVER(PARTITION BY s.creator),4) * 100 as pct_of_universe
    , SUM(s.total_power) OVER(ORDER BY s.total_power DESC NULLS LAST) as running_total
    , s.*
FROM supes_with_tot s
ORDER BY 6
----------------------------------------
-- TIP #11 - System catalog views 
----------------------------------------
SELECT * FROM user_tables;
SELECT * FROM all_tables;
SELECT * FROM hr.employees;
----------------------------------------
-- TIP #12 - Explain Plan / Execution Plan
----------------------------------------
EXPLAIN PLAN FOR  
SELECT prod_category, AVG(amount_sold)  
FROM   sh.sales s, sh.products p  
WHERE  p.prod_id = s.prod_id  
GROUP BY prod_category;

SELECT plan_table_output  
FROM TABLE(DBMS_XPLAN.DISPLAY('plan_table',null,'typical'));

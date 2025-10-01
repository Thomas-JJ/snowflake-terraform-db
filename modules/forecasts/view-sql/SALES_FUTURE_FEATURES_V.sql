WITH calendar AS (
    SELECT DATEADD(day, SEQ4(), CURRENT_DATE) AS DATE
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
),
locations AS (
    SELECT DISTINCT LOCATION
    FROM FGANALYTICS_DEV.SALES.ORDERS
),
calendar_by_loc AS (
    SELECT c.DATE, l.LOCATION
    FROM calendar c
    CROSS JOIN locations l
)

SELECT 
    c.LOCATION                              AS LOCATION,
    TO_TIMESTAMP_NTZ(c.DATE)                AS TIMESTAMP
FROM calendar_by_loc c
LEFT JOIN (
    SELECT DATE
    FROM MASTER.HOLIDAYS
) h
  ON h.DATE = c.DATE
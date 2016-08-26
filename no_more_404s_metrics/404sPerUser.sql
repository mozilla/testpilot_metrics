/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/981
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

SELECT
  date             AS date,
  IF(num_actions = 1, -- Label logics
    '1',
    IF(num_actions >= 16,
      '16+',
      CONCAT(CONCAT(CAST(num_actions AS varchar),'-'),CAST((2*num_actions-1) AS varchar))
    )
  )                AS num_404s,
  MAX(num_actions) AS num_actions,
  COUNT(*)         AS num_users
FROM
  (SELECT -- Change commented lines to make this day/week based
    FROM_UNIXTIME(7*24*60*60*FLOOR((
      ts/(1000*1000*1000*24*60*60) -- Day
      - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))) % 7 -- Day Number
    )/7))                                                       AS date, -- Week
    /*FROM_UNIXTIME(24*60*60*FLOOR(ts/(1000*1000*1000*24*60*60))) AS date, -- Day*/
    uuid                                                        AS uuid,
    CAST(POW(2,FLOOR(LOG2(COUNT(*)))) as bigint)              AS num_actions -- Powers of 2
  FROM wayback_daily
  WHERE
    uuid IS NOT NULL
    AND ts >= 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)  -- Min Date (Today - 9 weeks)
    AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
    AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
  GROUP BY 1,2
  )
GROUP BY 1,2
ORDER BY 3,1

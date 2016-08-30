/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/985
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

SELECT
  date                         AS date,
  COUNT(*)                     AS num_users,
  SUM(pings)                   AS num_pings,
  AVG(pings)                   AS average_pings,
  APPROX_PERCENTILE(pings,0.5) AS median_pings
FROM
  (SELECT -- Change commented lines to make this day/week based
    FROM_UNIXTIME(24*60*60*(
      FLOOR((ts/(1000*1000*1000*24*60*60) - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)/7)*7
       + (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)
    )                                                           AS date,   -- Week
    --FROM_UNIXTIME(24*60*60*FLOOR(ts/(1000*1000*1000*24*60*60))) AS date, -- Day
    uuid                                                        AS uuid,
    COUNT(*)                                                    AS pings
  FROM wayback_daily
  WHERE
    uuid IS NOT NULL
    AND ts >= 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)  -- Min Date (Today - 9 weeks)
    AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
    AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
  GROUP BY 1,2
  )
GROUP BY 1

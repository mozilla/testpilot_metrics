/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/982
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

SELECT -- Change commented lines to make this day/week based

  FROM_UNIXTIME(24*60*60*(
    FLOOR((ts/(1000*1000*1000*24*60*60) - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)/7)*7
     + (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)
  )                                                           AS date,   -- Week
  /*FROM_UNIXTIME(24*60*60*FLOOR(ts/(1000*1000*1000*24*60*60))) AS date, -- Day*/
  100.0*SUM(IF(action <> 'none' AND action IS NOT NULL,1,0))/COUNT(*) AS archiveRatio,
  COUNT(*)                                                            AS cnt
FROM wayback_daily
WHERE
  uuid IS NOT NULL
  AND ts >= 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)  -- Min Date (Today - 9 weeks)
  AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
  AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
GROUP BY 1

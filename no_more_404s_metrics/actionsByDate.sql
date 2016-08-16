/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/979
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

SELECT  -- Change commented lines to make this week based
  /*from_unixtime(7*24*60*60*floor((
      ts/(1000*1000*1000*24*60*60) -- Day
       - (floor(to_unixtime(CURRENT_TIMESTAMP)/(24*60*60))) % 7 -- Day Number
    )/7))                                                     AS date, -- Week*/
  from_unixtime(24*60*60*floor(ts/(1000*1000*1000*24*60*60))) AS date, -- Day
  action                                                      AS action,
  count(*)                                                    AS num_actions
FROM wayback_daily
WHERE
  action <> 'none'
  AND action IS NOT NULL
  AND uuid IS NOT NULL
  AND ts >= 1000*1000*1000*floor(to_unixtime(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)  -- Min Date (Today - 9 weeks)
  AND ts >= 1000*1000*1000*to_unixtime(date_parse('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
  AND ts <  1000*1000*1000*floor(to_unixtime(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
GROUP BY 1,
         2

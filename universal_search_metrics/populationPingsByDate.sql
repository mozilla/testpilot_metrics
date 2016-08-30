/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/744
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/-in-progress-universal-search-executive-summary
 */

SELECT
  date,
  AVG(num_users) OVER (ORDER BY daily.date ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING) AS seven_day_users,
  AVG(num_pings) OVER (ORDER BY daily.date ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING) AS seven_day_pings
FROM (
    SELECT
      FROM_UNIXTIME(24*60*60*FLOOR(ts/(1000*1000*1000*24*60*60))) AS date,
      COUNT(DISTINCT uuid) AS num_users,
      COUNT(*) AS num_pings
    FROM usearch_daily AS daily
    WHERE
      uuid                       IS NOT NULL
      AND Recommendationshown    IS NOT NULL
      AND Recommendationselected IS NOT NULL
      AND Selectedindex          IS NOT NULL
      AND (
        ts    <= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160706', '%Y%m%d'))
        OR ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160809', '%Y%m%d'))
      )
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160505', '%Y%m%d'))
      --AND ts >= 1000*1000*1000*floor(to_unixtime(CURRENT_TIMESTAMP)/(24*60*60) - 10*7)*(24*60*60) -- Min Date (Today - 10 weeks)
      AND ts < 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)
    GROUP BY 1
  ) daily
--WHERE date >= FROM_UNIXTIME(FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)) -- Min Date (Today - 9 weeks)
GROUP BY date,num_users,num_pings

/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/991
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

WITH tmp_user_times AS ( -- Get ping times by user
    SELECT
      uuid                AS uuid,
      ts/(1000*1000*1000) AS ts
    FROM wayback_daily
    WHERE
      uuid IS NOT NULL
      AND ts >= 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60)  -- Min Date (Today - 9 weeks)
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
      AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
  ),
  tmp_ping_data AS ( -- Get ping time vs previous ping by user
    SELECT
      endPing.uuid                                                                            AS uuid,
      endPing.ts                                                                              AS ts,
      MIN(IF(endPing.ts > startPing.ts, FLOOR((endPing.ts - startPing.ts)/(24*60*60)), 1000)) AS time_between
    FROM   tmp_user_times AS startPing
      JOIN tmp_user_times AS endPing   ON(startPing.uuid = endPing.uuid)
    WHERE endPing.ts >= startPing.ts -- Make sure that the ordering is appropriate
    GROUP BY 1,2
  )
-- Munge the data to get the correct data labels and percentages
SELECT
  IF(time_between=1000,
    'Inf',
    IF(time_between>=9,
       '9+',
       CAST(CAST(time_between AS bigint) AS varchar)
    )
  )                             AS time_between,
  100.0*COUNT(*)/MAX(total.cnt) AS num_pings
FROM tmp_ping_data
  CROSS JOIN (SELECT COUNT(*) AS cnt FROM tmp_ping_data) AS total
GROUP BY 1
ORDER BY 1

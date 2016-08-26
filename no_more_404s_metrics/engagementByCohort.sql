/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/975
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/wayback-machine-no-more-404s-executive-summary
 */

WITH tmp_user_start AS
  ( -- Get the start time of each user
    SELECT
      uuid,
      MIN(ts)/(1000*1000*1000) AS start_unix
    FROM wayback_daily
    WHERE
      uuid IS NOT NULL
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
      AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
    GROUP BY uuid
  ),
  tmp_counts_by_date AS
  ( -- Aggregated counts by date (day or week depending on logic)
    SELECT -- Change commented lines to make this day/week based
      FROM_UNIXTIME(7*24*60*60*FLOOR((
          start_unix/(24*60*60) -- Start Day
           - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))) % 7 -- Day Number
        )/7))                                                AS date,       -- Week
      FLOOR((ts/(1000*1000*1000) - start_unix)/(7*24*60*60)) AS day_number, -- Week
      /*FROM_UNIXTIME(24*60*60*FLOOR(start_unix/(24*60*60)))   AS date,       -- Day
      FLOOR((ts/(1000*1000*1000) - start_unix)/(24*60*60))   AS day_number, -- Day*/
      COUNT(DISTINCT start_time.uuid)                        AS total
    FROM
      wayback_daily       AS daily
      JOIN tmp_user_start AS start_time ON(daily.uuid = start_time.uuid)
    WHERE
      daily.uuid IS NOT NULL
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160804', '%Y%m%d')) -- Min Date (2016-08-04)
      AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60) -- Max Date (yesterday)
    GROUP BY 1,2
  )
SELECT
  data.date,
  data.day_number,
  data.total                AS value,
  base.total                AS total,
  1.0*data.total/base.total AS pct_total
FROM
  tmp_counts_by_date AS data
  JOIN tmp_counts_by_date AS base ON(data.date = base.date)
WHERE
  data.day_number > 0
  AND data.day_number < 10
  AND base.day_number = 0
ORDER BY 1,2

/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/684
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/-in-progress-universal-search-executive-summary
 */

WITH
  tmp_user_start AS (
    SELECT
      uuid,
      MIN(ts)/(1000*1000*1000) AS start_unix
    FROM usearch_daily
    WHERE
      uuid                       IS NOT NULL
      AND Recommendationshown    IS NOT NULL
      AND Recommendationselected IS NOT NULL
      AND Selectedindex          IS NOT NULL
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160505', '%Y%m%d'))
      AND ts < 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)
    GROUP BY uuid
  ), tmp_weekly_sum AS
  (
    SELECT
      date,
      day_number,
      SUM(IF(is_good_data,total,0))  AS total
    FROM (
        SELECT  -- Change commented lines to make this day/week based
          FROM_UNIXTIME(24*60*60*(
            FLOOR((start_unix/(24*60*60) - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)/7)*7
             + (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)
          )                                                      AS date,       -- Week
          FLOOR((ts/(1000*1000*1000) - start_unix)/(7*24*60*60)) AS day_number, -- Week
          --FROM_UNIXTIME(24*60*60*FLOOR(start_unix/(24*60*60)))   AS date,       -- Day
          --FLOOR((ts/(1000*1000*1000) - start_unix)/(24*60*60))   AS day_number, -- Day
          (
            (
              start_unix <= TO_UNIXTIME(DATE_PARSE('20160706', '%Y%m%d'))
              OR start_unix >= TO_UNIXTIME(DATE_PARSE('20160809', '%Y%m%d'))
            ) AND (
              ts <= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160706', '%Y%m%d'))
              OR ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160809', '%Y%m%d'))
            )
          )       AS is_good_data,
          COUNT(DISTINCT start.uuid)                             AS total
        FROM
          usearch_daily AS daily
          JOIN tmp_user_start AS start ON(daily.uuid = start.uuid)
        WHERE
          daily.uuid                 IS NOT NULL
          AND Recommendationshown    IS NOT NULL
          AND Recommendationselected IS NOT NULL
          AND Selectedindex          IS NOT NULL
          AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160505', '%Y%m%d'))
          AND ts <  1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)
        GROUP BY 1,2,3
        HAVING FLOOR((ts/(1000*1000*1000) - start_unix)/(7*24*60*60)) < 11
      )
    GROUP BY date, day_number
  )
SELECT
  week.date                 AS date,
  week.day_number           AS day_number,
  week.total                AS value,
  base.total                AS total--,
  --1.0*week.total/base.total AS pct_total
FROM
  tmp_weekly_sum AS week
  JOIN tmp_weekly_sum AS base ON(week.date = base.date)
WHERE
  week.day_number > 0
  AND week.day_number < 10
  AND base.day_number=0
ORDER BY date, day_number

/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/687
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/-in-progress-universal-search-executive-summary
 */

WITH
  tmp_weekly AS (
    SELECT
      FROM_UNIXTIME(24*60*60*(
        FLOOR((ts/(1000*1000*1000*24*60*60) - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)/7)*7
         + (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60)))%7)
      )                                                                            AS week,
      IF(Recommendationshown, IF(Recommendationselected, 1, 2), 3)                 AS label_id,
      IF(Recommendationshown, IF(Recommendationselected, 'Taken', 'Shown'), 'All') AS label,
      COUNT(*)                                                                     AS cnt
    FROM usearch_daily AS daily
    WHERE
      Didnavigate
      AND uuid                   IS NOT NULL
      AND Recommendationshown    IS NOT NULL
      AND Recommendationselected IS NOT NULL
      AND Selectedindex          IS NOT NULL
      AND ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160505', '%Y%m%d'))
      --AND ts >= 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60) - 9*7)*(24*60*60) -- Min Date (Today - 9 weeks)
      AND ts < 1000*1000*1000*FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)
      AND (
        ts    <= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160706', '%Y%m%d'))
        OR ts >= 1000*1000*1000*TO_UNIXTIME(DATE_PARSE('20160809', '%Y%m%d'))
      )
    GROUP BY 1, 2, 3
  )
SELECT
  (num.week) AS week,
  (CONCAT(CONCAT(num.label,' / '), denom.label)) AS label,
  (100.0*num.cnt/(num.cnt + denom.cnt)) AS pct
FROM tmp_weekly AS num
JOIN tmp_weekly AS denom ON(num.week=denom.week
                        AND num.label_id=denom.label_id-1)
WHERE num.label_id < 3

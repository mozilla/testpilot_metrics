/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: TODO@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/745
 * Dashboard: https://sql.telemetry.mozilla.org/dashboard/-in-progress-universal-search-executive-summary
 */

WITH
  tmp_weekly_usertotals AS (
    SELECT
      FROM_UNIXTIME(7*24*60*60*FLOOR((
        ts/(24*60*60*1000*1000*1000)
        - (FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))) % 7
      )/7)) AS week,
      uuid,
      IF(Recommendationshown, IF(Recommendationselected, 'Selected', 'Not Selected'), 'Not shown') AS label,
      COUNT(*) AS interactions
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
  ), tmp_weekly_totals AS (
    SELECT
      week,
      COUNT(DISTINCT uuid) AS num_users
    FROM tmp_weekly_usertotals
    GROUP BY 1
  ), predivision AS (
    SELECT
      a.week,
      label,
      num_users,
      SUM(interactions) AS label_interactions
    FROM tmp_weekly_usertotals a
      JOIN tmp_weekly_totals b ON(a.week = b.week)
    GROUP BY 1, 2, 3
  )
SELECT
  week,
  label,
  (1.0*label_interactions/num_users) AS avg_interactions
FROM predivision

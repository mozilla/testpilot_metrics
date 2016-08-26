/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: msamuel@mozilla.com
 * Status: Draft
 * URL: https://sql.telemetry.mozilla.org/queries/732/source
 * Dashboards: https://sql.telemetry.mozilla.org/dashboard/txp-executive-summary
 */

-- I'm considering joining with new user counts to spot areas of fluctuation with mau/dau.
/*WITH tmp_user_start AS (
  SELECT
    'universal-search@mozilla.com' AS test,
    DATE_FORMAT(FROM_UNIXTIME(start_ts),'%Y%m%d') AS day,
    COUNT(*) as num_new_users
  FROM (
    SELECT
      uuid,
      FLOOR(MIN(ts)/(1000*1000*1000*24*60*60))*(24*60*60) AS start_ts
    FROM usearch_daily
    WHERE
      Didnavigate
      AND Recommendationshown IS NOT NULL
      AND Recommendationselected IS NOT NULL
      AND Selectedindex IS NOT NULL
      AND activity_date >= '20160505'
      AND activity_date < DATE_FORMAT(FROM_UNIXTIME(FLOOR(TO_UNIXTIME(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)), '%Y%m%d')
    GROUP BY uuid,ts
  ) AS tmp
  GROUP BY 1, 2
)*/
WITH tmp_experiment_generations AS ( -- Right now new data doesn't overwrite old data, so we need the max(generated_on) values to filter the our query to the latest date
  SELECT
    test,
    MAX(generated_on) AS generated_on
  FROM fxa_mau_dau_daily
  WHERE
    day < DATE_FORMAT(CURRENT_TIMESTAMP, '%Y%m%d')
    AND day > DATE_FORMAT(DATE_ADD('day', -7*10, CURRENT_TIMESTAMP), '%Y%m%d')
  GROUP BY test
)
SELECT
  test_group,
  date,
  mau,
  dau,
  --num_new_users,
  engagement_ratio,
  smoothed_dau,
  smoothed_dau/mau AS smoothed_engagment_ratio
FROM  ( -- This unions Experiment data with General Data
        ( -- Individual Experiments calculations
          SELECT
            CASE txpExperiments.test
              WHEN '@activity-streams'            THEN 'Activity Stream'
              WHEN 'universal-search@mozilla.com' THEN 'Universal Search'
              WHEN 'tabcentertest1@mozilla.com'   THEN 'Tab Center'
              WHEN 'wayback_machine@mozilla.org'  THEN 'No More 404s'
              ELSE                                     'Unknown'
            END                                      AS test_group,
            DATE_PARSE(txpExperiments.day, '%Y%m%d') AS date,
            mau                                      AS mau,
            dau                                      AS dau,
            --COALESCE(newUsers.num_new_users,0)       AS num_new_users,
            1.0*dau/mau                              AS engagement_ratio,
            AVG(dau) OVER (
              PARTITION BY txpExperiments.test
              ORDER BY txpExperiments.day
              ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING
            )                                        AS smoothed_dau
          FROM
            fxa_mau_dau_daily txpExperiments
            JOIN tmp_experiment_generations generations ON (
              txpExperiments.test = generations.test
              AND txpExperiments.generated_on = generations.generated_on
            )
            /*LEFT JOIN tmp_user_start newUsers ON (
              txpExperiments.day = newUsers.day
              AND txpExperiments.test = newUsers.test
            )*/
          WHERE
            txpExperiments.day < DATE_FORMAT(CURRENT_TIMESTAMP, '%Y%m%d')
            AND txpExperiments.day > DATE_FORMAT(DATE_ADD('day', -7*10, CURRENT_TIMESTAMP), '%Y%m%d')
          GROUP BY
            txpExperiments.test,
            txpExperiments.day,
            txpExperiments.mau,
            txpExperiments.dau
            --newUsers.num_new_users
        )
        UNION ALL -- ===========================================================
        ( -- General TxP calculations
          SELECT
            'test Pilot'                       AS test_group,
            DATE_PARSE(day, '%Y%m%d')          AS date,
            mau                                AS mau,
            dau                                AS dau,
            --COALESCE(newUsers.num_new_users,0) AS num_new_users,
            1.0*dau/mau                        AS engagement_ratio,
            AVG(dau) OVER (
              /*PARTITION BY 1*/
              ORDER BY txpAll.day
              ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING
            )                                  AS smoothed_dau
          FROM testpilot_engagement_ratio txpAll
          WHERE
            txpAll.day < DATE_FORMAT(CURRENT_TIMESTAMP, '%Y%m%d')
            AND txpAll.day > dATE_FORMAT(DATE_ADD('day', -7*10, CURRENT_TIMESTAMP), '%Y%m%d')
          GROUP BY
            txpAll.day,
            txpAll.mau,
            txpAll.dau
            --newUsers.num_new_users
        )
    )
WHERE date > DATE_ADD('day', -7*9, CURRENT_TIMESTAMP)
ORDER BY 1, 2

/*
 * Owner: rrayborn@mozilla.com
 * Reviewer: msamuel@mozilla.com
 * Status: Draft
 * Dashboard(s):
    * https://sql.telemetry.mozilla.org/dashboard/txp-executive-summary
 */

/*  -- I'm considering joining with new user counts to spot areas of fluctuation with MAU/DAU.
WITH tmp_user_start AS
  (SELECT
    'universal-search@mozilla.com' AS TEST,
    date_format(from_unixtime(start_ts),'%Y%m%d') AS DAY,
    COUNT(*) as num_new_users
  FROM (SELECT uuid,
            floor(min(ts)/(1000*1000*1000*24*60*60))*(24*60*60) AS start_ts
    FROM usearch_daily
    WHERE Didnavigate
      AND Recommendationshown IS NOT NULL
      AND Recommendationselected IS NOT NULL
      AND Selectedindex IS NOT NULL
      AND activity_date >= '20160505'
      AND activity_date < date_format(from_unixtime(floor(to_unixtime(CURRENT_TIMESTAMP)/(24*60*60))*(24*60*60)), '%Y%m%d')
     GROUP BY 1) AS tmp
   GROUP BY 1,2
  )*/
WITH tmp_experiment_generations AS ( -- Right now new data doesn't overwrite old data, so we need the max(generated_on) values to filter the our query to the latest date
  SELECT
    TEST,
    MAX(generated_on) AS generated_on
  FROM fxa_mau_dau_daily
  WHERE DAY > date_format(date_add('day', -60, CURRENT_TIMESTAMP), '%Y%m%d') -- Last 60 days
        AND DAY < '99999999'
  GROUP BY 1
)
SELECT test_group,
       date,
       mau,
       dau,
       --num_new_users,
       engagement_ratio,
       smoothed_dau,
       smoothed_dau/mau as smoothed_engagment_ratio
FROM  ( -- This unions Experiment data with General Data
        ( -- Individual Experiments calculations
          SELECT if(txpExperiments.TEST = '@activity-streams','Activity Stream',if(txpExperiments.TEST = 'universal-search@mozilla.com','Universal Search',if(txpExperiments.TEST = 'tabcentertest1@mozilla.com','Tab Center',if(txpExperiments.TEST = 'wayback_machine@mozilla.org','No More 404s','Unknown')))) AS test_group,
                 date_parse(txpExperiments.DAY, '%Y%m%d') AS date,
                 MAU AS mau,
                 DAU AS dau,
                 --COALESCE(newUsers.num_new_users,0) AS num_new_users,
                 1.0*DAU/MAU AS engagement_ratio,
                 avg(DAU) OVER (PARTITION BY txpExperiments.TEST ORDER BY txpExperiments.DAY ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING) AS smoothed_dau
          FROM fxa_mau_dau_daily txpExperiments
               JOIN tmp_experiment_generations generations ON(txpExperiments.TEST = generations.TEST AND txpExperiments.generated_on = generations.generated_on)
               --LEFT JOIN tmp_user_start newUsers ON(txpExperiments.DAY = newUsers.DAY and txpExperiments.TEST = newUsers.TEST)
          WHERE txpExperiments.DAY < date_format(CURRENT_TIMESTAMP, '%Y%m%d')
          GROUP BY txpExperiments.TEST,
                   txpExperiments.DAY,
                   txpExperiments.MAU,
                   txpExperiments.DAU
                   --newUsers.num_new_users
        )
        UNION ALL -- ===========================================================
        ( -- General TxP calculations
          SELECT 'Test Pilot' AS test_group,
                 date_parse(DAY, '%Y%m%d') AS date,
                 MAU AS mau,
                 DAU AS dau,
                 --COALESCE(newUsers.num_new_users,0) AS num_new_users,
                 1.0*DAU/MAU AS engagement_ratio,
                 avg(DAU) OVER (/*PARTITION BY 1*/ ORDER BY txpAll.DAY ROWS BETWEEN 6 PRECEDING AND 0 FOLLOWING) AS smoothed_dau
          FROM testpilot_engagement_ratio txpAll
          WHERE txpAll.DAY < date_format(CURRENT_TIMESTAMP, '%Y%m%d')
          GROUP BY txpAll.DAY,
                   txpAll.MAU,
                   txpAll.DAU
                   --newUsers.num_new_users
        )
    )
WHERE date > date_add('day', -60, CURRENT_TIMESTAMP) -- Last 60 days
ORDER BY 1,
         2

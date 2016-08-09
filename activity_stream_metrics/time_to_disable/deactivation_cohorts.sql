/*
 * Owner: msamuel@mozilla.com
 * Status: Draft
 * Dashboard(s):
 * https://sql.telemetry.mozilla.org/queries/908#1561
 */

WITH date_range AS
  (SELECT day AS date FROM
    (SELECT (DATEADD(DAY, -ROW_NUMBER() over (ORDER BY TRUE), SYSDATE::DATE)) as day 
    FROM activity_stream_events_daily)
  WHERE day >= '05/10/2016'
  ORDER BY 1 ASC),

disabled_clients AS
  (SELECT client_id, MAX(date) AS last_disabled
  FROM activity_stream_events_daily
  WHERE event = 'disable'
  GROUP BY client_id),

usage_dates AS
  (SELECT * FROM
    (SELECT disabled_clients.client_id,
        MIN(date) first_visit,
        MAX(date) last_visit,
        MIN(disabled_clients.last_disabled) last_disabled
    FROM disabled_clients
    LEFT JOIN activity_stream_stats_daily stats
    ON disabled_clients.client_id = stats.client_id
    GROUP BY disabled_clients.client_id)
  WHERE last_visit <= last_disabled),

activity_table AS
  (SELECT date_range.date, usage_dates.client_id
  FROM date_range
  LEFT JOIN usage_dates
  ON date_range.date >= usage_dates.first_visit AND date_range.date <= usage_dates.last_disabled
  ORDER BY client_id, date),


cohort_count as (
  select
    date_trunc('week', date) as date, count(distinct client_id) as count
  from activity_table
  group by 1
)

select * from
  (select date, period as week_number, retained_users as value, new_users as total,
  max(period) over (PARTITION BY date) AS max_week_num
  from (
    select
      date_trunc('week', anow.date) as date,
      date_diff('week', date_trunc('week', anow.date), date_trunc('week', athen.date)) as period,
      max(cohort_size.count) as new_users, 
      count(distinct anow.client_id) as retained_users,
      count(distinct anow.client_id) /
        max(cohort_size.count)::float as retention
    from activity_table anow
    left join activity_table as athen on
      anow.client_id = athen.client_id
      and anow.date <= athen.date
      and (anow.date + interval '84 days') >= athen.date
    left join cohort_count as cohort_size on
      anow.date = cohort_size.date
    group by 1, 2) t
  where period is not null
  and date > current_date - interval '84 days'
  and date > '05-08-2016'
  order by date, period)
where week_number < max_week_num
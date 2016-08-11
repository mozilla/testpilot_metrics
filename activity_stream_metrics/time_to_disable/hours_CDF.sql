/*
 * Owner: msamuel@mozilla.com
 * Status: Draft
 * Dashboard(s):
 * https://sql.telemetry.mozilla.org/queries/907#1559
 */

WITH disabled_clients AS
  (SELECT client_id, MAX(receive_at) AS last_disabled
  FROM activity_stream_events_daily
  WHERE event = 'disable'
  GROUP BY client_id),

usage_date AS
  (SELECT disabled_clients.client_id,
      MIN(receive_at) first_visit,
      MAX(receive_at) last_visit,
      MIN(disabled_clients.last_disabled) last_disabled
  FROM disabled_clients
  LEFT JOIN activity_stream_stats_daily stats
  ON disabled_clients.client_id = stats.client_id
  GROUP BY disabled_clients.client_id)

SELECT client_id, 
  DATEDIFF('hour', first_visit, last_disabled) AS hours_enabled,
  CUME_DIST () OVER (ORDER BY hours_enabled) * 100 AS CumeDist
FROM usage_date
WHERE last_visit <= last_disabled
ORDER BY hours_enabled DESC
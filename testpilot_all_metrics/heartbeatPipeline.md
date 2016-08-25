## Info
* Owner: rrayborn@mozilla.com
* Reviewer: TODO@mozilla.com
* Status: Draft

## Background
We currently only send HB ratings to SurveyGizmo as a URL parameter, but we wanted to be able to display it side by side with our other metrics.

## Pipeline
### Summary
A high-level view of the pipeline looks as follows:

1. User hits SurveyGizmo survey
2. [*Instant Pushing*] SG Daemon populates spreadsheet row with rating data
3. [*Daily Polling*] Re:dash pulls data into charts

### Implementation
#### SurveyGizmo -> Google Sheets
We use the [built-in SurveyGizmo Google Sheets integration](https://help.surveygizmo.com/help/google-spreadsheet-integration) to get data from SurveyGizmo into Re:dash.  The logic can be found in the "Heartbeat Spreadsheet" Question Libary question.  This element incorporates 2 parts:

1. A Hidden Value that records the current datetime
2. A Google Spreadsheet Action

*The Hidden Value must be place before the Google Spreadsheet Action; SG doesn't always insert it in the correct order.*


The Google Spreadsheet Action sets the following named columns in the spreadsheet:

1. **experiment** - [*Static Value*] The name of the experiment
2. **datetime** - [*Hidden Value*] The current datetime from the Hidden Value mentioned above
3. **interval** - [*URL Param*] A URL parameter for the # of days since installation
4. **rating** - [*URL Param*] A URL parameter for the star rating given in the HB prompt
5. **date** - [*Static Value*] The Google Sheets formula to munge datetime to date
6. **week** - [*Static Value*] The Google Sheets formula to munge datetime to week 
7. **month** - [*Static Value*] The Google Sheets formula to munge datetime to month

The reason that we insert Google Sheets formulas with 5-7 is because SG is appending new rows, so it's the easiest way to insure that formulas get populated for these rows.  If you have to implement this elsewhere you only should need to update the 'experiment' value and the Sheet to populate.

#### Google Sheet internal logic
Each experiment outputs to its own Sheet in [this Spreadsheet](https://docs.google.com/spreadsheets/d/1SDv1xE6YnFNu-4s0PTZg9LQZLbHmTULXnd-8kBf0oBk/edit).  These Sheets are then combined into the "Combined Data" Sheet (for auditing, not the most efficient structure due to redundancy).  From there the "Queries" Sheet uses the built-in SQL-like query language to aggregate the chart data into the structure that we want in Re:dash.  From there we filter this data into independent sheets for each Re:dash query.

#### Google Sheets -> Re:dash
We've given the Re:dash pipeline user<sup>1</sup> access to the Spreadsheet so that we can query it directly.

## Validation
Things that I've validated
* Correct rating/interval/etc data flows into Google Sheets
* You can input formulas from SG into Google Sheets
* Google Sheets does not need an actual client view to update the formulas
* Re:dash Charts look reasonable and update

## The Future

### Known Failure Conditions
Google Sheets are limited to 2 million cells.  We collect 14 cells per response.  This means that we can collect approximately 140,000 responses before this needs refactored.  As of 2016/08/25 we have 10700 HB responses in all experiments, so we should have decent headroom.  **We do not know if Google Sheets formula computing delays may become more of a bottleneck than storage constraints.**

### Making things less janky e.g Productionizing the Pipeline
If we're happy with the data that we're receiving, then we should probably move everything into a telemetry-based workflow.  It is designed to scale and has dozens of real engineers that can help us instead of one analyst who's decent at hacking workarounds :).  This is how things work in Firefox Desktop Heartbeat.

## Links
* Re:dash
  * Queries
    * [Heartbeat Rating by Interval](https://sql.telemetry.mozilla.org/queries/1073/source#1871)
    * [Early Heartbeat Rating by Week](https://sql.telemetry.mozilla.org/queries/1072/source#1869)
    * [Heartbeat Last Update](https://sql.telemetry.mozilla.org/queries/1077/source#table)
  * Dashboards
    * [TxP: Executive Summary](https://sql.telemetry.mozilla.org/dashboard/txp-executive-summary#edit_dashboard_dialog)
  * [Documentation on Google Sheets integration](http://docs.redash.io/en/latest/datasources.html#google-spreadsheets)
* Google Sheets
  * [Pipeline Data](https://docs.google.com/spreadsheets/d/1SDv1xE6YnFNu-4s0PTZg9LQZLbHmTULXnd-8kBf0oBk/edit)
* SurveyGizmo
  * [SurveyGizmo help article on Google Spreadsheet](https://help.surveygizmo.com/help/google-spreadsheet-integration)

## Footnotes
1. gspread@pipeline-sql-prod.iam.gserviceaccount.com

SELECT "year", "month", "day", "hour", "minute", "path", "responsecode" AS "statuscode", COUNT(*) AS "count"
FROM "wsi-accesslog"."accesslog"
GROUP BY "year", "month", "day", "hour", "minute", "path", "responsecode"

-- TrafficPatternQuery

SELECT "path", method, statuscode as statusCode, count(*) as "count"
FROM athenalog
GROUP BY "path", method, statuscode;

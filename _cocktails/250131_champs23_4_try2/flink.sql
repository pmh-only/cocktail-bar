%flink.ssql

DROP TABLE IF EXISTS flink;
CREATE TABLE flink (
  `method` STRING,
  `path` STRING,
  `statuscode` STRING,
  `time` TIMESTAMP(0),
  WATERMARK FOR `time` AS `time` - INTERVAL '1' SECOND
)
WITH (
  'connector' = 'kinesis',
  'stream' = 'log-stream',
  'aws.region' = 'us-east-1',
  'scan.stream.initpos' = 'LATEST',
  'format' = 'json'
);

--

%flink.ssql

SELECT window_start, window_end, `path`, `method`, count(*) AS request_count, SUM(IF(statuscode LIKE '4__', 1, 0)) as `request_error_count`, SUM(IF(statuscode LIKE '5__', 1, 0)) as `server_error_count`
FROM TABLE(HOP(TABLE flink, DESCRIPTOR(`time`), INTERVAL '1' MINUTE, INTERVAL '3' MINUTE))
GROUP BY window_start, window_end, `path`, `method`;

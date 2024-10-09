%flink.ssql

CREATE TABLE applog_parsed (
    `method` STRING,
    `path` STRING,
    `query` STRING,
    `size` INT,
    `year` BIGINT,
    `month` BIGINT,
    `day` BIGINT,
    `hour` BIGINT
)
PARTITIONED BY (
    `year`, `month`, `day`, `hour`
)
WITH (
  'connector' = 'filesystem',
  'path' = 's3://project-applicationlog/test',
  'format' = 'json',
  'sink.partition-commit.policy.kind' = 'success-file',
  'sink.partition-commit.delay' = '30sec',
  'sink.rolling-policy.file-size' = '1MB',
  'sink.rolling-policy.rollover-interval' = '30sec',
  'sink.rolling-policy.check-interval' = '30sec'
);

-- 


%flink.pyflink

env = StreamExecutionEnvironment.get_execution_environment()

env.enable_checkpointing(10 * 1000)
env.get_checkpoint_config().set_checkpointing_mode(CheckpointingMode.EXACTLY_ONCE)

--

%flink.ssql(type=update)

INSERT INTO applog_parsed (`method`, `path`, `query`, `size`, `year`, `month`, `day`, `hour`)
SELECT `method`, SPLIT_INDEX(`path`, '?', 0) AS `path`, SPLIT_INDEX(`path`, '?', 1) AS `query`, `size`, YEAR(`time`), MONTH(`time`), DAYOFMONTH(`time`), HOUR(`time`)
FROM applog2;

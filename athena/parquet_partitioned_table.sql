CREATE EXTERNAL TABLE `athenalog`(
  `hour` string COMMENT '', 
  `minute` string COMMENT '', 
  `second` string COMMENT '', 
  `path` string COMMENT '', 
  `method` string COMMENT '', 
  `statuscode` string COMMENT '', 
  `responsetime` string COMMENT '')
PARTITIONED BY ( 
  `year` string COMMENT '', 
  `month` string COMMENT '', 
  `day` string COMMENT '')
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
STORED AS INPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://wsi-pmhn-datalake-for-develop/log/'
TBLPROPERTIES (
  'projection.day.range'='1,31', 
  'projection.day.type'='integer', 
  'projection.enabled'='true', 
  'projection.month.range'='1,12', 
  'projection.month.type'='integer', 
  'projection.year.range'='2025,2030', 
  'projection.year.type'='integer', 
  'storage.location.template'='s3://wsi-pmhn-datalake-for-develop/log/year=${year}/month=${month}/day=${day}/')

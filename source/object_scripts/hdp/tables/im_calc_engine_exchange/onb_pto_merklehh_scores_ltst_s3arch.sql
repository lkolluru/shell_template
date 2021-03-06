DROP TABLE ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_pto_merklehh_scores_ltst_s3arch;
CREATE EXTERNAL TABLE IF NOT EXISTS ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_pto_merklehh_scores_ltst_s3arch(
matchcode_sha256 varchar(255),
score double,
rank double,
rundate_import timestamp,
rundate_sas_process date)
PARTITIONED BY (
archive_date varchar(100))
ROW FORMAT SERDE
'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
'gs://pch_mapr_im_hdlp_calcengine/${hivevar:DEP_ENV}/cold/onb/scoredata/onb_pto_merklehh_scores_ltst'
;
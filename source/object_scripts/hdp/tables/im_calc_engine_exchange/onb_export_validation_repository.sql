CREATE EXTERNAL TABLE IF NOT EXISTS ${hivevar:DEP_ENV}_im_calc_engine_exchange.onb_export_validation_repository
(
    load_env                         varchar(100),
    object_validation_severity       varchar(100),
    object_validation_output_flag    int,
    object_validation_output_message varchar(500),
    object_validation_query_id       varchar(500)
)
    PARTITIONED BY (object_name varchar(100),load_time date)
    STORED AS ORC
    LOCATION "maprfs:/im/calcengine/${hivevar:DEP_ENV}/hot/onb/scoredata/onb_export_validation_repository";
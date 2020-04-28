
drop table if exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.oflnsel_hdl_campaigninstructionfile; 

create external table if not exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.oflnsel_hdl_campaigninstructionfile
LIKE ${hivevar:DEP_ENV}_calc_engine_schema.sa_calc_engine_exchange_oflnsel_hdl_campaigninstructionfile
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' 
WITH SERDEPROPERTIES ( 
"  'field.delim'=',', "
"  'line.delim'='\n', "
"  'serialization.format'=',') "
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 'maprfs:/sa/calcengine/campaign/uat/hot/ceframework/oflnsel/20190501/import/oflnsel_hdl_campaigninstructionfile/datafiles'
TBLPROPERTIES ('avro.schema.url'='/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${hivevar:DEP_ENV}/oflnsel/schema/hdp/sa_calc_engine_exchange/oflnsel_hdl_campaigninstructionfile.avsc', 
               'skip.header.line.count'='1',
               'comment'='oflnsel');

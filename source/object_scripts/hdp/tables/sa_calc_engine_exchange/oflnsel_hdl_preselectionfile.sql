
drop table if exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.oflnsel_hdl_preselectionfile; 

create external table if not exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.oflnsel_hdl_preselectionfile
LIKE ${hivevar:DEP_ENV}_calc_engine_schema.sa_calc_engine_exchange_oflnsel_hdl_preselectionfile
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
LOCATION 'maprfs:/sa/calcengine/campaign/uat/hot/ceframework/oflnsel/20190501/import/oflnsel_hdl_preselectionfile/datafiles'
TBLPROPERTIES ('avro.schema.url'='/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${hivevar:DEP_ENV}/oflnsel/schema/hdp/sa_calc_engine_exchange/oflnsel_hdl_preselectionfile.avsc', 
               'skip.header.line.count'='1',
               'comment'='oflnsel');

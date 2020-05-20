drop table if exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.onb_hdl_historical_variables; 

create external table if not exists ${hivevar:DEP_ENV}_sa_calc_engine_exchange.onb_hdl_historical_variables
STORED AS AVRO
LOCATION 'gs://pch_mapr_sa_hdlp_calcengine/sa/hdlp/analytics/${hivevar:DEP_ENV}/hot/ceframework/onb/onb_hdl_historical_variables'
TBLPROPERTIES ('avro.schema.url'='/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${hivevar:DEP_ENV}/onb/schema/hdp/sa_calc_engine_exchange/onb_hdl_historical_variables.avsc');

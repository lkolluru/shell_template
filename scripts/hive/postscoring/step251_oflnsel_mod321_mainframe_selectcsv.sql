source ${env:PROJ_HIVE_POSTSCORING_DIR}/oflnsel_modsro_hive_params.hql ;
set mapreduce.job.name=${PROJ_HIVE_MR_JOBNM}${env:HIVE_SHELLFILE_NM};

set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.max.dynamic.partitions.pernode=10000;
set hive.exec.max.dynamic.partitions=5000;
set hive.cli.print.header=true;
set hive.resultset.use.unique.column.names=false;


!echo "Proceeding to selct csv query" ;

select concat_ws(',', cast(cust_id as varchar(12)), model_nm, geographic_loc, cast(score_no as varchar(25)), selection_dt, customer_strength, cast(mailing_ct as varchar(10)), cast(paradigm as varchar(10)), score_date, cast(mag_total as varchar(5)), cast(merch_general as varchar(5)), cast(total_mag_merch as varchar(5)), cast(auto_ship as varchar(5)), cast(top_coincident_x as varchar(5)), cast(top_main_x as varchar(5)), cast(deeper_main_x as varchar(5)), cast(valid_mail_count as varchar(5))) as cnctrw
from ${SCORES_EXP_DB_NAME}.${SCORES_EXP_LTST_TABLE} ;
source ${env:PROJ_HIVE_POSTSCORING_DIR}/oflnsel_hybridoutput_hive_params.hql ;
set mapreduce.job.name=${PROJ_HIVE_MR_JOBNM}${env:HIVE_SHELLFILE_NM};

set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.max.dynamic.partitions.pernode=10000;
set hive.exec.max.dynamic.partitions=5000;

!echo "Load the scoring data into latest scores table"  ;

insert overwrite table ${SCORES_IMP_DB_NAME}.${SCORES_IMP_LTST_TABLE}
select cust_id,cust_part_seq_no,extract_run_ts,campaign_cd,flowchart_id,flowchart_run_id,selection_year,selection_week,delivery_paradigm_year,delivery_paradigm_week,variable_derived_dt,selection_dt,
line_of_business,effort_id,effort_type_cd,geo_loc,zipcode,cust_st_prov_cd,cust_st_prov_abr,stream_cd,distant_ind,mc_last_init_exist,mc_first_init_exist,dash_cust_ind,initial_selection_segment,initial_mailing_key,
initial_score_no,initial_model_name,initial_expected_value_amt,random_sample_ind,force_inclusion_ind,package_cd,analytics_initial_key_cd,analytics_final_key_cd,analytics_final_score_no,
analytics_final_model_name,analytics_expected_value_amt from ${SCORING_DB_NAME}.${SAS_SCORES_TABLE};
--uat_im_calc_engine_exchange.oflnsel_hybridoutput ; 
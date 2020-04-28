#!/bin/bash

set -euo pipefail
set -E -o functrace
source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/$1/oflnsel/config/oflnsel_env.sh
source ${PROCESS_SHELL_TEMPLATE_SCRIPT}
source ${ARCHIVE_LOG_SHELL}
#Functions

function cleanup() {
    echo -e $(generic_log_message) "Cleanup function is called." 2>&1 | tee -a ${log_file}

}
#Functions CUSTOM TO THE IMPORT TRIG SCRIPTS ONLY

function inputfiledelay_warn() {

    #trap send_mainscript_failure_email ERR

    declare -i curr_hour=$(expr $(date +%H) + 0)

    declare -i curr_min=$(expr $(date +%M) + 0)

    if ([ ${curr_hour} -eq ${ALERT_HOUR_1} ] || [ ${curr_hour} -eq ${ALERT_HOUR_2} ]) && [ ${curr_min} -ge ${ALERT_MIN_FROM} ] && [ ${curr_min} -le ${ALERT_MIN_TO} ]; then

        LAST_TRIG_DATE=$(ls -lt --time-style='+%Y-%m-%d' ${FILE_WATCH_IMPORT_COMPLETE_DIR}/oflnsel_import_trigger_20* | head -1 | awk '{ print $6 }')

        if [ ${LAST_TRIG_DATE} != $(date +"%Y-%m-%d") ]; then
            info_log "Sending warning mail as upstream files are yet to be delivered"
            mail -s "${email_subject_env}: NOT RECEIVED - oflnsel scoring files not received " ${failure_to_email} <<<"Files would not be delivered for Monday refresh Still waiting for oflnsel scoring files processes. Please follow up "
            warn_log "upstream files are yet to be delivered failing the script with non zero error code"
            exit 1

        fi

    else
        info_log "threshold evaluation for oflnsel scoring files complete"

    fi

}

function synchronize_corn_process() {

    LOCKFILE=${temp_lock_file}

    if [ -e ${LOCKFILE} ] && kill -0 $(cat ${LOCKFILE}); then

        info_log "process already running" 2>&1 | tee -a ${log_file}

        exit
    fi

    ## future enhancement.

}

function run_archive_logs() {

    info_log "evaluation of the log directories for  ${ARCHIVE_LOG_DIRECTORY} started"

    eval_archivedirectory ${ARCHIVE_LOG_DIRECTORY}

    info_log "archival of the logs in the directories for ${ACTIVE_LOG_DIRECTORY} started"

    process_archivelogs ${ACTIVE_LOG_DIRECTORY} ${ARCHIVE_LOG_DIRECTORY}

    info_log "archival of the logs in the directories for ${ARCHIVE_LOG_DIRECTORY} completed"

}

trap cleanup SIGINT SIGHUP SIGTERM EXIT
trap send_mainscript_failure_email ERR

#Main Program

############################################ STEP 1:

#Initialize Vairables and Crontrol Log File

############################################

return_exit_code=0

#Prepare the cron log files for archival

prepare_cronlog_file

#synchronize_corn_process 2>&1 | tee -a ${log_file} future enhancement to make sure cron is not overlapping each other to create multiple trigger files.

info_log "${FUNCTIONAL_GROUP} trig evaluation started: $(date +"%Y_%m_%d_%H_%M_%S")" 2>&1 | tee -a ${log_file}

#Prepare the trigger files and rundates
#( file is auto crated by the git process no need to create one )

info_log "Command executed: ${0}" 2>&1 | tee -a ${log_file}

OFLNSEL_LAST_RUN_DATE_FILE="${FILE_WATCH_IMPORT_DIR}/oflnsel_import_last_run_date_file"

if [ -e ${OFLNSEL_LAST_RUN_DATE_FILE} ]; then

    TRIG_FILE="${FILE_WATCH_IMPORT_READY_DIR}/oflnsel_import_trigger_$(date +"%Y%m%d").trig"
    OFLNSEL_LAST_RUN_DATE=$(date +%Y-%m-%d -d "$(cat $OFLNSEL_LAST_RUN_DATE_FILE | awk '{ print $1 }') ")
    OFLNSEL_CURRWEEK_RUN_DATE=$(date +%Y-%m-%d -d "$(cat $OFLNSEL_LAST_RUN_DATE_FILE | awk '{ print $1 }') + 6 day")
    TMP_SQOOP_RESULT="${log_directory}/tmp_sqoop_imp_$(date +"%Y_%m_%d_%H_%M_%S")";
else

    fatal_log "${TRIG_FILE} not present in the control location" 2>&1 | tee -a ${log_file}
    exit 1

fi

############################################ STEP 2:

#Threshold control evaluation

############################################

inputfiledelay_warn 2>&1 | tee -a ${log_file}
return_exit_code=$?

############################################ STEP 3:

#Upstream dependency evaluation for the cmpgn process using prod logging table.

############################################

if [ "${OFLNSEL_LAST_RUN_DATE}" != "$(date +"%Y-%m-%d")" ]; then

    info_log "last successful execution date in $OFLNSEL_LAST_RUN_DATE_FILE is OFLNSEL_LAST_RUN_DATE: ${OFLNSEL_LAST_RUN_DATE}" 2>&1 | tee -a ${log_file}

    info_log "proceeding with the evaluation of the prod logging table in the cluster for upstream dependencies" 2>&1 | tee -a ${log_file}
    if [ "${OFLNSEL_HYBRID_CMPGN_FILE_CHCK}" != "ON" ]; then

        TRIG_QUERY="select max(to_date(from_unixtime(unix_timestamp(cast(insert_ts as varchar(19)), 'yyyy/MM/dd HH:mm:ss')))) as cur_proc_date,count(*) 
                    from prod_logging.general_logging where to_date(from_unixtime(unix_timestamp(cast(insert_ts as varchar(19)), 'yyyy/MM/dd HH:mm:ss'))) > '${OFLNSEL_CURRWEEK_RUN_DATE}'
                    and (object_name='stop_repeater_modsro_current' or object_name='week20_mod321_current')
                    and team='calcengine' and exec_status='success'"

        info_log "trigger query used to determine the execution is as shown below:" 2>&1 | tee -a ${log_file}
        info_log " $TRIG_QUERY" 2>&1 | tee -a ${log_file}

        HIVE_RES=$(/usr/local/bin/hive-bigdata -e "${TRIG_QUERY}")

        info_log "HIVE_RES=${HIVE_RES}" 2>&1 | tee -a ${log_file}
        ################test failed need to capture the logs of the execution in the log file.

        EXPORT_COUNT=$(echo $HIVE_RES | awk '{ print $2 }')
        info_log "export count for comparision is as follows EXPORT_COUNT:  ${EXPORT_COUNT}" 2>&1 | tee -a ${log_file}

        CURR_RUN_DATE=$(echo $HIVE_RES | awk '{ print $1 }')
        ######TESTING ONLY ENABLED############ EXPORT_COUNT=2
        ######TESTING ONLY ENABLED############ CURR_RUN_DATE=${CURRENT_RUN_DATE}
        
        info_log "latest rundate for comparision is follows CURR_RUN_DATE:  ${CURR_RUN_DATE}" 2>&1 | tee -a ${log_file}

        #current programmable objects are 2 once hybrid output is in this would change to 3 and move to the config

        if [ "$(echo $HIVE_RES | awk '{ print $2 }')" != "2" ]; then

            info_log "upstream processes (mainframe file  not available yet) are not refreshed will continue to evaluate the input in another 10 mins" 2>&1 | tee -a ${log_file}

        else
            if [ -e ${ARCHIVE_LOG_SHELL} ]; then

                run_archive_logs 2>&1 | tee -a ${log_file}

            else
                error_log "${ARCHIVE_LOG_SHELL} does not exist" 2>&1 | tee -a ${log_file}
                exit 1

            fi
            
            info_log "all upstream files are refreshed proceeding with the campaign files check" 2>&1 | tee -a ${log_file}

            prepare_log_file

            if [[ ${ENV_FLAG} != 'prod' ]]; then
                touch ${TRIG_FILE}
                echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
            else
                touch ${TRIG_FILE}
                echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
            fi
        fi
    fi
    else

        TRIG_QUERY="select max(to_date(from_unixtime(unix_timestamp(cast(insert_ts as varchar(19)), 'yyyy/MM/dd HH:mm:ss')))) as cur_proc_date,count(*) 
                    from prod_logging.general_logging where to_date(from_unixtime(unix_timestamp(cast(insert_ts as varchar(19)), 'yyyy/MM/dd HH:mm:ss'))) > '${OFLNSEL_CURRWEEK_RUN_DATE}'
                    and (object_name='stop_repeater_modsro_current' or object_name='week20_mod321_current' or object_name='agg_omnicore_custid_flatten' or object_name='agg_omnicustom_customer_purchase_category' or object_name='dmsm10_dmdo002_current')
                    and team='calcengine' and exec_status='success'"

        info_log "trigger query used to determine the execution is as shown below:" 2>&1 | tee -a ${log_file}
        info_log " $TRIG_QUERY" 2>&1 | tee -a ${log_file}

        HIVE_RES=$(/usr/local/bin/hive-bigdata -e "${TRIG_QUERY}")

        info_log "HIVE_RES=${HIVE_RES}" 2>&1 | tee -a ${log_file}
        ################test failed need to capture the logs of the execution in the log file.

        EXPORT_COUNT=$(echo $HIVE_RES | awk '{ print $2 }')
        info_log "export count for comparision is as follows EXPORT_COUNT:  ${EXPORT_COUNT}" 2>&1 | tee -a ${log_file}

        CURR_RUN_DATE=$(echo $HIVE_RES | awk '{ print $1 }')
        ######TESTING ONLY ENABLED############ EXPORT_COUNT=2
        ######TESTING ONLY ENABLED############ CURR_RUN_DATE=${CURRENT_RUN_DATE}
        
        info_log "latest rundate for comparision is follows CURR_RUN_DATE:  ${CURR_RUN_DATE}" 2>&1 | tee -a ${log_file}

        #current programmable objects are 2 once hybrid output is in this would change to 3 and move to the config

        if [ "$(echo $HIVE_RES | awk '{ print $2 }')" != "5" ]; then

            info_log "upstream processes (mainframe file  not available yet) are not refreshed will continue to evaluate the input in another 10 mins" 2>&1 | tee -a ${log_file}

        else
        
            info_log "all upstream files are refreshed proceeding with the campaign files check" 2>&1 | tee -a ${log_file}

            prepare_log_file
            sqoop eval --connect "${CONNSTR}" --query "EXEC appinfo.poll_importstatusinfo @s_functionalgroup = '${FUNCTIONAL_GROUP_UPPER}'" > $TMP_SQOOP_RESULT
            cat $TMP_SQOOP_RESULT 2>&1 | tee -a ${log_file};
            #| tail -1 | awk -F'|' '{ print $2 }' | awk '{ print $1 }'
            str=`cat ${TMP_SQOOP_RESULT}  `
            info_log "str: $str" 2>&1 | tee -a ${log_file};
            if [[ $str == *['|']* ]]; then
                
                info_log "Import poll-set has been done for all 3 file"
                sqoop_res=`sed -n '12p' < $TMP_SQOOP_RESULT | grep '^|' | awk -F'|' '{ print $2 }' | awk '{ print $1 }'`;
                info_log "sqoop_res: $sqoop_res" 2>&1 | tee -a ${log_file};

                sqoop_res1=`sed -n '13p' < $TMP_SQOOP_RESULT | grep '^|' | awk -F'|' '{ print $2 }' | awk '{ print $1 }'`;
                info_log "sqoop_res1: $sqoop_res1" 2>&1 | tee -a ${log_file};

                sqoop_res2=`sed -n '14p' < $TMP_SQOOP_RESULT | grep '^|' | awk -F'|' '{ print $2 }' | awk '{ print $1 }'`;
                info_log "sqoop_res2: $sqoop_res2" 2>&1 | tee -a ${log_file} ;


                    if [ "$sqoop_res2" == "oflnsel_hdl_preselectionfile" ] && [ "$sqoop_res" == "oflnsel_hdl_campaignfile" ] && [ "$sqoop_res1" == "oflnsel_hdl_campaigninstructionfile" ]; then
                        info_log "preselection file is available"
                            #Archive the prior week and prior run logs once we receive a succesful trigger only
                            #if not continue to load logs in cron logs can alter this process if there is a easier way
                            if [ -e ${ARCHIVE_LOG_SHELL} ]; then

                                run_archive_logs 2>&1 | tee -a ${log_file}

                            else
                                error_log "${ARCHIVE_LOG_SHELL} does not exist" 2>&1 | tee -a ${log_file}
                                exit 1

                            fi
                        if [[ ${ENV_FLAG} != 'prod' ]]; then
                                touch ${TRIG_FILE}
                                echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
                        else
                                touch ${TRIG_FILE}
                                echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
                        fi
                    else
                        info_log "pre selection file is not available yet" 2>&1 | tee -a ${log_file};
                    fi 2>&1 | tee -a ${log_file};
            info_log "all upstream (mainframe file  are available) are refreshed proceeding with the downstream  refresh" 2>&1 | tee -a ${log_file}
            else
                info_log "Import poll-set has not been done for all 3 file so its empty" 2>&1 | tee -a ${log_file};
            fi 2>&1 | tee -a ${log_file};  
        

        fi
    fi
else

    info_log "skipping the load status check as process was successfully completed" 2>&1 | tee -a ${log_file}

fi
#rm $TMP_SQOOP_RESULT
exit 2>&1 | tee -a ${log_file}

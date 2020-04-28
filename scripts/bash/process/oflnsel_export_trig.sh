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

    if ([ ${curr_hour} -eq ${ALERT_HOUR_3} ] || [ ${curr_hour} -eq ${ALERT_HOUR_4} ]) && [ ${curr_min} -ge ${ALERT_MIN_FROM} ] && [ ${curr_min} -le ${ALERT_MIN_TO} ]; then

        LAST_TRIG_DATE=$(ls -lt --time-style='+%Y-%m-%d' ${FILE_WATCH_EXPORT_COMPLETE_DIR}/oflnsel_export_trigger_20* | head -1 | awk '{ print $6 }')

        if [ ${LAST_TRIG_DATE} != $(date +"%Y-%m-%d") ]; then

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

OFLNSEL_LAST_RUN_DATE_FILE="${FILE_WATCH_EXPORT_DIR}/oflnsel_export_last_run_date_file"

if [ -e ${OFLNSEL_LAST_RUN_DATE_FILE} ]; then

    TRIG_FILE="${FILE_WATCH_EXPORT_READY_DIR}/oflnsel_export_trigger_$(date +"%Y%m%d").trig"
    OFLNSEL_LAST_RUN_DATE=$(date +%Y-%m-%d -d "$(cat $OFLNSEL_LAST_RUN_DATE_FILE | awk '{ print $1 }') + 6 day")
    TMP_SQOOP_RESULT="${log_directory}/tmp_sqoop_$(date +"%Y_%m_%d_%H_%M_%S")"
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

if [[ "${OFLNSEL_LAST_RUN_DATE}" < "$(date +"%Y-%m-%d")" ]]; then

    info_log "last successful execution date in $OFLNSEL_LAST_RUN_DATE_FILE is OFLNSEL_LAST_RUN_DATE: ${OFLNSEL_LAST_RUN_DATE}" 2>&1 | tee -a ${log_file}

    info_log "proceeding with the evaluation of the prod logging table in the cluster for upstream dependencies" 2>&1 | tee -a ${log_file}

    TRIG_QUERY="SELECT MAX(CAST(targetexchangedatetime AS date)) AS CURR_RUN_DATE,COUNT(*) AS SAS_COUNT  FROM 		[hdl_calc_engine_metastore].logginginfo.variableexchangelogrepositoryinfo WHERE exportid IN (24) and [targetexchangestatusid] = 12 and 	[targetexchangeoverallstatus] = 1 and [sourceexchangerecordcount] = [targetexchangerecordcount] and cast(targetexchangedatetime as date)  > '$OFLNSEL_LAST_RUN_DATE'"

    info_log "trigger query used to determine the execution is as shown below:" 2>&1 | tee -a ${log_file}
    info_log " $TRIG_QUERY" 2>&1 | tee -a ${log_file}
    # Obtain the info from the env file not hard codings.
    sqoop eval --connect "${CONNSTR}" --query "${TRIG_QUERY}" >$TMP_SQOOP_RESULT

    echo "Result of sqoop query" 2>&1 | tee -a ${log_file}

    cat $TMP_SQOOP_RESULT 2>&1 | tee -a ${log_file}
    ################test failed need to capture the logs of the execution in the log file.

    EXPORT_COUNT=$(cat ${TMP_SQOOP_RESULT} | grep '^|' | tail -1 | awk -F'|' '{ print $3 }' | awk '{ print $1 }')
    info_log "export count for comparision is as follows EXPORT_COUNT:  ${EXPORT_COUNT}" 2>&1 | tee -a ${log_file}

    CURR_EXPORT_DATE=$(cat ${TMP_SQOOP_RESULT} | grep '^|' | tail -1 | awk -F'|' '{ print $2 }' | awk '{ print $1 }')
    ######TESTING ONLY ENABLED############ EXPORT_COUNT=2
    ######TESTING ONLY ENABLED############ CURR_EXPORT_DATE=${CURRENT_RUN_DATE}
    info_log "latest rundate for comparision is follows CURR_EXPORT_DATE:  ${CURR_EXPORT_DATE}" 2>&1 | tee -a ${log_file}

    #current programmable objects are 2 once hybrid output is in this would change to 3 and move to the config

    if [ "$EXPORT_COUNT" != "1" ]; then

        info_log "upstream processes (SAS scoring not completed yet) are not refreshed will continue to evaluate the input in another 10 mins" 2>&1 | tee -a ${log_file}
        rm $TMP_SQOOP_RESULT
    else

        info_log "all upstream (SAS scoring finished for oflnsel) are refreshed proceeding with the downstream  refresh" 2>&1 | tee -a ${log_file}

        prepare_log_file

        info_log "all upstream (SAS scoring finished for oflnsel) are refreshed proceeding with the downstream  refresh" 2>&1 | tee -a ${log_file}

        if [[ ${ENV_FLAG} != 'prod' ]]; then
            touch ${TRIG_FILE}
            #echo ${CURR_EXPORT_DATE} >${OFLNSEL_LAST_RUN_DATE_FILE}
            echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
        else
            touch ${TRIG_FILE}
            echo $(date +"%Y-%m-%d" -d "last saturday") >${OFLNSEL_LAST_RUN_DATE_FILE}
        fi

    fi

#rm $TMP_SQOOP_RESULT

else

    info_log "skipping the load status check as process was successfully completed" 2>&1 | tee -a ${log_file}

fi

exit 2>&1 | tee -a ${log_file}

#!/bin/bash 

#Set Global Variables
set -o pipefail
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Main Program

#CHANGE FOLLOWING VARIABLES ACCORDING TO ENV
export HIVE_SHELLFILE_NM=$(basename ${0});

export model_name="modsro";
export load_env="${CODE_ENV_FLAG}";
export model_count_logging_file="${MODEL_COUNTS_LOG_FILE}";
export model_count=`/usr/local/bin/hive-bigdata -e "select count(*) from ${MODEL_COUNT_MODSRO_TABLE}"`;

#Setup new or edit log file.
prepare_log_file;

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

if [ "${model_count}" != "" ] && [ "${model_count}" != "0" ]; then
echo "${model_name},$(date '+%Y-%m-%d %H:%M:%S'),${model_count},${load_env}" >> ${model_count_logging_file}

info_log "Entry made into model_count_log table" 2>&1 | tee -a ${step_log_file};
else
error_log "Hive table: ${MODEL_COUNT_MODSRO_TABLE}  is empty or count retrieval failed. Log entry not made.  please check" 2>&1 | tee -a ${step_log_file};
exit 1
fi


exit $?  ;


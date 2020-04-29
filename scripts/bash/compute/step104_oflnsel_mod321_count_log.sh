#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Main Program

load_control_table() {

    HIVE_SHELLFILE_NM=$(basename ${0})
    model_name="mod321"
    load_env="${CODE_ENV_FLAG}"
    model_count_logging_file="${MODEL_COUNTS_LOG_FILE}"
    model_count=$(beehive "select count(*) from ${MODEL_COUNT_MOD321_TABLE}")

    info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

    if [ "${model_count}" != "" ] && [ "${model_count}" != "0" ]; then
        echo "${model_name},$(date '+%Y-%m-%d %H:%M:%S'),${model_count},${load_env}" >>${model_count_logging_file}

        info_log "Entry made into model_count_log table" 2>&1 | tee -a ${step_log_file}
    else
        error_log "Hive table: ${MODEL_COUNT_MOD321_TABLE}  is empty or count retrieval failed. Log entry not made.  please check" 2>&1 | tee -a ${step_log_file}
        exit 1
    fi

}

main() {
    info_log "$FUNCNAME:Command executed: ${0}"

    if ! load_control_table; then

        exit 1

    fi

}

#Setup new or edit log file.
prepare_log_file

main 2>&1 | tee -a ${step_log_file}

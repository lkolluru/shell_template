#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source "${STEP_SHELL_TEMPLATE_SCRIPT}"
source "${FILE_HANDLER_SCRIPT}"
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Main Program

function load_control_table() {

    {
        HIVE_SHELLFILE_NM=$(basename "${0}") &&
            model_name="onb_historical" &&
            load_env="${CODE_ENV_FLAG}" &&
            model_count_logging_file="${MODEL_COUNTS_LOG_FILE}"
    }
    load_control_table_rc=$?
    [ $load_control_table_rc -ne 0 ] && error_log "${FUNCNAME[0]}: error initalizing the vars" && return 1

    model_count=$(beehivecounts "select count(*) from ${MODEL_COUNT_HISTORICAL_TABLE}")
    
    evaluation_ret_code=$?
    
    [ $evaluation_ret_code -ne 0 ] && error_log "${FUNCNAME[0]}: error executing the beehive command" && return 1

    info_log "$HIVE_SHELLFILE_NM produced $model_count records to be loaded to the control table"

    if [ "${model_count}" != "" ] && [ "${model_count}" != "0" ]; then

        echo "${model_name},$(date '+%Y-%m-%d %H:%M:%S'),${model_count},${load_env}" >>"${model_count_logging_file}"

        info_log "${FUNCNAME[0]}:Entry made into model_count_log table"

    else

        error_log "${FUNCNAME[0]}:Hive table: ${MODEL_COUNT_HISTORICAL_TABLE}  is empty or count retrieval failed. Log entry not made.  please check"

        return 1

    fi

}

function main() {

    info_log "${FUNCNAME[0]}:Command executed: ${0}"

    if ! load_control_table; then

        exit 1

    fi

}

#Setup new or edit log file.
prepare_log_file

main 2>&1 | tee -a "${step_log_file}"

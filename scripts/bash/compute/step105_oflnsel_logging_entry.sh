#!/bin/bash

#Set Global Variables --up for deprication.
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

function load_control_table() {

    export HIVE_SHELLFILE_NM=$(basename ${0})
    info_log "Command executed: ${0}"
    echo "calcengine,hybrid_etl,${ENV_FLAG},oflnsel,oflnsel_hybridoutput_ltst,success,$(date '+%Y/%m/%d %H:%M:%S:000000000')" >>${PROD_LOGGING_FILE}
    info_log "Entry made into prod_logging table"

}

function main() {

    info_log "$FUNCNAME:Command executed: ${0}"

    if ! load_control_table; then

        exit 1

    fi

}

#Setup new or edit log file.
prepare_log_file

main 2>&1 | tee -a ${step_log_file}

#!/bin/bash

#Set Global Variables
set -euo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap 'gen_step_error ${LINENO} ${?}' ERR
trap clean_up SIGINT SIGHUP SIGTERM EXIT

function copy_campaigninstruction_files() {

    if ! test_directory_contents ${CAMPAIGNINSTRUCTION_FILE_DIR}; then
        return 1
    fi

    campaigninstruction_file=$(find ${CAMPAIGNINSTRUCTION_FILE_DIR} -type f -name '*.gz')

    [ -z ${campaigninstruction_file} ] && error_log "$FUNCNAME:${campaigninstruction_file} is empty value failing the process" && return 1

    campaigninstruction_file_name=$(basename ${campaigninstruction_file})

    campaigninstruction_file_path=${CAMPAIGNINSTRUCTION_FILE_DIR}/${campaigninstruction_file_name}

    if ! test_path ${campaigninstruction_file_path}; then
        return 1
    fi

    if ! test_directory ${CAMPAIGNINSTRUCTION_DATA_FILE_DIR}; then
        return 1
    fi
    if ! remove_items ${CAMPAIGNINSTRUCTION_DATA_FILE_DIR}; then
        return 1
    fi
    if ! copy_item ${campaigninstruction_file_path} ${CAMPAIGNINSTRUCTION_DATA_FILE_DIR}; then
        return 1
    fi
}

function archive_processed_files() {

    archive_date=$(date +%Y-%m-%d)

    current_campaigninstruction_file=$(find ${CAMPAIGNINSTRUCTION_FILE_DIR} -type f -name '*_N.gz')

    [ -z ${current_campaigninstruction_file} ] && error_log "$FUNCNAME:${current_campaigninstruction_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_campaigninstruction_file})

    archive_file_path=${CAMPAIGNINSTRUCTION_ARCHIVE_ZIP_DIR}

    if ! move_item ${CAMPAIGNINSTRUCTION_FILE_DIR}/${original_zip_file_name} ${archive_file_path}; then

        return 1

    fi

}

function post_process_validations() {

    exchange_table_query="select count(1) cnt from dev_sa_calc_engine_exchange.oflnsel_hdl_campaigninstructionfile;"

    _hive_restults=$(beehive "${exchange_table_query}")

    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) failed to execute successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: ${_hive_restults} are obtained from the query results" && return 0
}

function main() {

    info_log "$FUNCNAME:Command executed: ${0}"

    if ! copy_campaigninstruction_files; then
        exit 1
    fi
    if ! archive_processed_files; then
        exit 1
    fi
    if ! post_process_validations; then
        exit 1
    fi
}

#Main Program

#Setup new or edit log file.
prepare_log_file

main 2>&1 | tee -a ${step_log_file}

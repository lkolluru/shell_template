#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

function unzip_tarfiles() {

    test_directory_contents ${CAMPAIGN_FILE_DIR}

    [ $? -ne 0 ] && return 1

    current_campaign_file=$(find ${CAMPAIGN_FILE_DIR} -type f -name *_N.tar.gz)

    [ -z ${current_campaign_file} ] && error_log "$FUNCNAME:${current_campaign_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_campaign_file})

    info_log "file uzipped is ${original_zip_file_name}"

    test_path ${CAMPAIGN_FILE_DIR}/${original_zip_file_name}

    [ $? -ne 0 ] && return 1

    test_directory ${UNZIP_CAMPAIGN_FILE_DIR}

    [ $? -ne 0 ] && return 1

    expand_archive ${CAMPAIGN_FILE_DIR}/${original_zip_file_name} ${UNZIP_CAMPAIGN_FILE_DIR}

    [ $? -ne 0 ] && return 1

}

function move_campaign_files() {

    test_directory_contents ${UNZIP_CAMPAIGN_FILE_DIR}

    [ $? -ne 0 ] && return 1

    test_directory ${CAMPAIGN_DATA_FILE_DIR}

    [ $? -ne 0 ] && return 1

    remove_items ${CAMPAIGN_DATA_FILE_DIR}

    [ $? -ne 0 ] && return 1

    move_items ${UNZIP_CAMPAIGN_FILE_DIR} ${CAMPAIGN_DATA_FILE_DIR}

    [ $? -ne 0 ] && return 1

}

function archive_processed_files() {

    archive_date=$(date +%Y-%m-%d)

    current_campaign_file=$(find ${CAMPAIGN_FILE_DIR} -type f -name *_N.tar.gz)

    [ -z ${current_campaign_file} ] && error_log "$FUNCNAME:${current_campaign_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_campaign_file})

    archive_file_path=${CAMPAIGN_ARCHIVE_ZIP_DIR}

    move_item ${CAMPAIGN_FILE_DIR}/${original_zip_file_name} ${archive_file_path}

    [ $? -ne 0 ] && return 1

}

function post_process_validations() {

    exchange_table_query="select count(1) cnt from dev_sa_calc_engine_exchange.oflnsel_hdl_campaignfile;"

    _hive_restults=$(beehive "${exchange_table_query}")

    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) completed successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: ${_hive_restults} are obtained from the query results" && return 0
}

function main() {

    unzip_tarfiles
    [ $? -ne 0 ] && exit 1
    move_campaign_files
    [ $? -ne 0 ] && exit 1
    archive_processed_files
    [ $? -ne 0 ] && exit 1
    post_process_validations
    [ $? -ne 0 ] && exit 1
}

#Main Program

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

main 2>&1 | tee -a ${step_log_file}

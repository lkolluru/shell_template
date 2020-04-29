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

    if ! test_directory_contents ${CAMPAIGN_FILE_DIR}; then

         return 1

    fi
    current_campaign_file=$(find ${CAMPAIGN_FILE_DIR} -type f -name '*_N.tar.gz')

    [ -z ${current_campaign_file} ] && error_log "$FUNCNAME:${current_campaign_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_campaign_file})

    info_log "file uzipped is ${original_zip_file_name}"

    if ! test_path ${CAMPAIGN_FILE_DIR}/${original_zip_file_name}; then

        return 1
    fi
    if ! test_directory ${UNZIP_CAMPAIGN_FILE_DIR}; then

        return 1
    fi
    if ! expand_archive ${CAMPAIGN_FILE_DIR}/${original_zip_file_name} ${UNZIP_CAMPAIGN_FILE_DIR}; then

        return 1
    fi
}

function move_campaign_files() {

    if ! test_directory_contents ${UNZIP_CAMPAIGN_FILE_DIR}; then 

     return 1

    fi 

    if ! test_directory ${CAMPAIGN_DATA_FILE_DIR}; then 

     return 1

    fi 

    if ! remove_items ${CAMPAIGN_DATA_FILE_DIR}; then 

     return 1

    fi 

    if ! move_items ${UNZIP_CAMPAIGN_FILE_DIR} ${CAMPAIGN_DATA_FILE_DIR}; then 

     return 1

    fi 
}

function archive_processed_files() {

    archive_date=$(date +%Y-%m-%d)

    current_campaign_file=$(find ${CAMPAIGN_FILE_DIR} -type f -name '*_N.tar.gz')

    [ -z ${current_campaign_file} ] && error_log "$FUNCNAME:${current_campaign_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_campaign_file})

    archive_file_path=${CAMPAIGN_ARCHIVE_ZIP_DIR}

    if ! move_item ${CAMPAIGN_FILE_DIR}/${original_zip_file_name} ${archive_file_path}; then 

     return 1

    fi 

}

function post_process_validations() {

    exchange_table_query="select count(1) cnt from dev_sa_calc_engine_exchange.oflnsel_hdl_campaignfile;"

    _hive_restults=$(beehive "${exchange_table_query}")

    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) completed successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: ${_hive_restults} are obtained from the query results" && return 0
}

function main() {

    if ! unzip_tarfiles; then
        exit 1
    fi
    if ! move_campaign_files; then
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

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

main 2>&1 | tee -a ${step_log_file}

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

    if test_directory_contents ${PRESELECTION_FILE_DIR}; then 

     return 1

    fi 

    current_preselection_file=$(find ${PRESELECTION_FILE_DIR} -type f -name '*_N.tar.gz')

    [ -z ${current_preselection_file} ] && error_log "$FUNCNAME:${current_preselection_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_preselection_file})

    info_log "$FUNCNAME:file uzipped is ${original_zip_file_name}"

    if ! test_path ${PRESELECTION_FILE_DIR}/${original_zip_file_name}; then 

     return 1
    fi 

    if ! test_directory ${UNZIP_PRESELECTION_FILE_DIR}; then 

     return 1
    fi 
    if ! expand_archive ${PRESELECTION_FILE_DIR}/${original_zip_file_name} ${UNZIP_PRESELECTION_FILE_DIR}; then

     return 1
    fi 

}

function move_preselection_files() {

    if ! test_directory_contents ${UNZIP_PRESELECTION_FILE_DIR}; then 

     return 1
    fi 

    preselection_file_unzip=$(find ${UNZIP_PRESELECTION_FILE_DIR} -type f -name 'PROD_PRESELECTION_*.csv')

    [ -z ${preselection_file_unzip} ] && error_log "$FUNCNAME:${preselection_file_unzip} is empty value failing the process" && return 1

    preselection_unzip_file_name=$(basename ${preselection_file_unzip})

    preselection_file_unzip_path=${UNZIP_PRESELECTION_FILE_DIR}/${preselection_unzip_file_name}

    if ! test_path ${preselection_file_unzip_path}; then 

     return 1
    fi 

    if ! test_directory ${PRESELECTION_DATA_FILE_DIR}; then 

     return 1

    fi 

    if ! remove_items ${PRESELECTION_DATA_FILE_DIR}; then 

     return 1

    fi

    if ! move_item ${preselection_file_unzip_path} ${PRESELECTION_DATA_FILE_DIR}; then 

     return 1

    fi 
}

function post_process_validations() {

    exchange_table_query="select count(1) cnt from dev_sa_calc_engine_exchange.oflnsel_hdl_preselectionfile;"

    _hive_restults=$(beehive "${exchange_table_query}")

    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) completed successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: ${_hive_restults} are obtained from the query results" && return 0
}

function archive_processed_files() {

    archive_date=$(date +%Y-%m-%d)

    current_preselection_file=$(find ${PRESELECTION_FILE_DIR} -type f -name '*_N.tar.gz')

    [ -z ${current_preselection_file} ] && error_log "$FUNCNAME:${current_preselection_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_preselection_file})

    archive_file_path=${PRESELECTION_ARCHIVE_ZIP_DIR}

    if ! test_directory ${PRESELECTION_ARCHIVE_ZIP_DIR}; then 

     return 1
     fi 

    if ! move_item ${PRESELECTION_FILE_DIR}/${original_zip_file_name} ${archive_file_path}; then 

     return 1
     fi 

}

function main() {

    if ! unzip_tarfiles; then

        exit 1

    fi

    if ! move_preselection_files; then

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

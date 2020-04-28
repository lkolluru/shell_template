#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR


#Functions

function check_file_name() {

    test_directory_contents ${PRESELECTION_FILE_DIR}

    [ $? -ne 0 ] && return 1

    current_preselection_file=$(find ${PRESELECTION_FILE_DIR} -type f -name *_N.tar.gz)

    [ -z ${current_preselection_file} ] && error_log "$FUNCNAME:${current_preselection_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_preselection_file})

    info_log "$FUNCNAME:file name for evaluation is ${original_zip_file_name}"
    
    test_path ${PRESELECTION_FILE_DIR}/${original_zip_file_name}

    [ $? -ne 0 ] && return 1

}

function check_file_size() {

    current_preselection_file=$(find ${PRESELECTION_FILE_DIR} -type f -name *_N.tar.gz)

    [ -z ${current_preselection_file} ] && error_log "$FUNCNAME:${current_preselection_file} is empty value failing the process" && return 1

    original_zip_file_name=$(basename ${current_preselection_file})

    info_log "$FUNCNAME:file name for evaluation is ${original_zip_file_name}"

    test_content ${PRESELECTION_FILE_DIR}/${original_zip_file_name}
    
    [ $? -ne 0 ] && return 1
}

function check_file_date() {

    wk_date=$(date +"%Y%m%d" -d "last saturday")
    current_preselection_file=$(find ${PRESELECTION_FILE_DIR} -type f -name *_N.tar.gz)
    original_zip_file_name=$(basename ${current_preselection_file})
    processed_zip_filename=$(echo ${original_zip_file_name} | cut -f2 -d'_')
    preselection_file_date=$(expr substr ${processed_zip_filename} 1 8)

    if [ $preselection_file_date -gt $wk_date ]; then
        info_log "$ENV_FLAG_UPPER:OFLNSEL-New Preselection File received for date $preselection_file_date."
    else
        error_log "$ENV_FLAG_UPPER:OFLNSEL-ERROR.Please check Preselection file -Previous week file is received."
        return 1
    fi
}

function main() {

    check_file_name

    [ $? -ne 0 ] && exit 200
    
    check_file_size
    
    [ $? -ne 0 ] && exit 200

}

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

main 2>&1 | tee -a ${step_log_file}

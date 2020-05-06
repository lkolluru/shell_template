#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

function extract_scores_hive_exchange_data_csv() {

    info_log "$FUNCNAME:Scores export of ${OFLNSEL_MODEL_NAME} being processed"

    {
        SELECTION_DATE_ID=$(date +"%Y%m%d" -d "last saturday") &&
            SCORES_FILES_ROOT="${OFLNSEL_MODEL_NAME}_Scores_Details_${SELECTION_DATE_ID}" && 
            SCORES_CSV_FILE_NAME="${SCORES_FILES_ROOT}.csv" &&
            EXPORT_CSV_FILE_PATH="${OFNLSEL_SCORES_CSV_FILE_DIR}"/"${SCORES_CSV_FILE_NAME}" &&
            EXPORT_HIVE_QUERY=" set hive.resultset.use.unique.column.names=false;
                                SELECT * 
                                FROM ${ENV_FLAG_UPPER}_IM_CALC_ENGINE_EXCHANGE.oflnsel_${OFLNSEL_MODEL_NAME}_scores_export_ltst;"
    }
    variable_inti_ret_code=$?

    [ $variable_inti_ret_code -ne 0 ] && error_log "$FUNCNAME: unable to initialize vairables" && return 1

    if ! beehivecsv "${EXPORT_HIVE_QUERY}" "${EXPORT_CSV_FILE_PATH}"; then

        return 1

    fi
}

function extract_scores_hive_exchange_cntrlfile_txt() {

    info_log "$FUNCNAME:Control file export of ${OFLNSEL_MODEL_NAME} being processed"

    {
        SELECTION_DATE_ID=$(date +"%Y%m%d" -d "last saturday") &&
            SCORES_CSV_CONTROL_FILE_NAME="${OFLNSEL_MODEL_NAME}_Scores_Trailer_${SELECTION_DATE_ID}.TXT" &&
            EXPORT_CSV_CONTROL_FILE_PATH="${OFLNSEL_SCORES_FILECOUNT_FILES_DIR}"/"${SCORES_CSV_CONTROL_FILE_NAME}" &&
            EXPORT_HIVE_CONTROL_COUNT_QUERY="SELECT '${SCORES_FILES_ROOT}',count(1) 
                                             FROM ${ENV_FLAG_UPPER}_IM_CALC_ENGINE_EXCHANGE.oflnsel_${OFLNSEL_MODEL_NAME}_scores_export_ltst;"
    }
    variable_inti_ret_code=$?

    [ $variable_inti_ret_code -ne 0 ] && error_log "$FUNCNAME: unable to initialize vairables" && return 1

    if ! beehivecsvnoheader "${EXPORT_HIVE_CONTROL_COUNT_QUERY}" "${EXPORT_CSV_CONTROL_FILE_PATH}"; then

        return 1

    fi
}

function consolidate_data_files_archival() {

    info_log "$FUNCNAME:export data consoliation of ${OFLNSEL_MODEL_NAME} being processed"

    if ! copy_item ${EXPORT_CSV_CONTROL_FILE_PATH} ${OFLNSEL_SCORES_DATA_FILES_DIR}; then
        return 1
    fi

    if ! copy_item ${EXPORT_CSV_FILE_PATH} ${OFLNSEL_SCORES_DATA_FILES_DIR}; then
        return 1
    fi

    return 0

}

function validate_exported_data_files() {

    info_log "$FUNCNAME:validation of export data consoliation of ${OFLNSEL_MODEL_NAME} being processed"

    if ! measure_item ${EXPORT_CSV_FILE_PATH}; then
        return 1

    else

        beehive_export_item_count=$(measure_item "${EXPORT_CSV_FILE_PATH}")
        info_log "$FUNCNAME: Beehive exported ${beehive_export_item_count} records"

    fi

        readarray -t control_file_parser <"${EXPORT_CSV_CONTROL_FILE_PATH}"

        [ "${#control_file_parser[@]}" -ne 1 ] && error_log "$FUNCNAME:control file needs to have only a single record" && return 1

        IFS=',' read -ra control_file_value_array <<<$(echo "${control_file_parser[0]}")

        control_file_item_count=${control_file_value_array[1]}

        info_log "$FUNCNAME: control file exported ${control_file_item_count} records"

    if [ "${control_file_item_count}" != "${beehive_export_item_count}" ]; then

        error_log "$FUNCNAME:control file table count does not match hive count"

        return 1

    else

        return 0

    fi

}

function compress_scores_data_zip() {

        info_log "$FUNCNAME:Scores zipping of ${OFLNSEL_MODEL_NAME} being processed"

        CDA_ZIP_FILE_NAME="${SCORES_FILES_ROOT}T.zip"

        if ! compress_archive "${OFLNSEL_SCORES_DATA_FILES_DIR}" "${OFLNSEL_SCORES_PREPZIP_FILES_DIR}" "${CDA_ZIP_FILE_NAME}" ; then 
            
            return 1 
        fi 


}

function transfer_scores_data_ftp() {

        info_log "$FUNCNAME:Scores zipping of ${OFLNSEL_MODEL_NAME} being processed"

        CDA_ZIP_FILE_NAME="${SCORES_FILES_ROOT}T.zip"

        if ! compress_archive "${OFLNSEL_SCORES_DATA_FILES_DIR}" "${OFLNSEL_SCORES_PREPZIP_FILES_DIR}" "${CDA_ZIP_FILE_NAME}" ; then 
            
            return 1 
        fi 


}

function preprocess() {

    info_log "$FUNCNAME:System eval and cleanup for scoring export module: ${0}"
    #### intialize the system variables
    export OFLNSEL_MODEL_NAME="modsro"
    export OFLNSEL_SCORES_TRANSFER_ROOT=${FILE_ROOT_DIR}/${OFLNSEL_MODEL_NAME}
    export OFNLSEL_SCORES_CSV_FILE_DIR=${OFLNSEL_SCORES_TRANSFER_ROOT}/csvfile/
    export OFLNSEL_SCORES_DATA_FILES_DIR=${OFLNSEL_SCORES_TRANSFER_ROOT}/datafiles/
    export OFLNSEL_SCORES_FILECOUNT_FILES_DIR=${OFLNSEL_SCORES_TRANSFER_ROOT}/filecounts/
    export OFLNSEL_SCORES_PREPZIP_FILES_DIR=${OFLNSEL_SCORES_TRANSFER_ROOT}/compressfilestozip/
    #TODO group the commands but could loose flexibility on return code eval, include test_directorycontents as well

    if test_directory_contents ${OFNLSEL_SCORES_CSV_FILE_DIR}; then
        if ! remove_items ${OFNLSEL_SCORES_CSV_FILE_DIR}; then
            return 1
        fi
    else
        warn_log "$FUNCNAME: ${OFNLSEL_SCORES_CSV_FILE_DIR} does not have any contents"
    fi

    if test_directory_contents ${OFLNSEL_SCORES_DATA_FILES_DIR}; then
        if ! remove_items ${OFLNSEL_SCORES_DATA_FILES_DIR}; then
            return 1
        fi
    else
        warn_log "$FUNCNAME: ${OFLNSEL_SCORES_DATA_FILES_DIR} does not have any contents"
    fi

    if test_directory_contents ${OFLNSEL_SCORES_FILECOUNT_FILES_DIR}; then
        if ! remove_items ${OFLNSEL_SCORES_FILECOUNT_FILES_DIR}; then
            return 1
        fi
    else
        warn_log "$FUNCNAME: ${OFLNSEL_SCORES_FILECOUNT_FILES_DIR} does not have any contents"
    fi

    if test_directory_contents ${OFLNSEL_SCORES_PREPZIP_FILES_DIR}; then
        if ! remove_items ${OFLNSEL_SCORES_PREPZIP_FILES_DIR}; then
            return 1
        fi
    else
        warn_log "$FUNCNAME: ${OFLNSEL_SCORES_PREPZIP_FILES_DIR} does not have any contents"
    fi

    return 0

}

function main() {

    info_log "$FUNCNAME:Command executed: ${0}"

    if ! preprocess; then
        exit 1
    fi

    if ! extract_scores_hive_exchange_data_csv; then
        exit 1
    fi

    if ! extract_scores_hive_exchange_cntrlfile_txt; then
        exit 1
    fi

    if ! validate_exported_data_files; then
        exit 1
    fi

    if ! consolidate_data_files_archival; then
        exit 1
    fi

    if ! compress_scores_data_zip; then 

        exit 1 
    fi 

}

prepare_log_file

main 2>&1 | tee -a ${step_log_file}

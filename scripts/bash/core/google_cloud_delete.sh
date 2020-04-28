#!/bin/bash

source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/config/oflnsel_env.sh
source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/scripts/bash/core/step_shell.sh
source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/scripts/bash/core/filehandler_shell.sh
set -euo pipefail
set -o errtrace
trap 'gen_shell_jar_error ${LINENO} ${?}' ERR

#functions
#######################################
# Cloud Strorage hdfs Handler Functions Repository Module
# Cloud Storage hdfs Modules:
#   cloud_exportdirectory_load

#######################################
function cloud_exportdirectory_load() {

    [ $# -ne 1 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

    #TODAY_ARCHIVE_DATE= "$(date +"%Y-%m-%d")"
    local CLOUD_STORAGE_DIR="${1}"
    local EVAL_DIR="$(echo "${1}" | sed 's/\*//g')"

    info_log "$FUNCNAME: CLOUD STORAGE DIRECTORY BEING EVALUATED: is ${EVAL_DIR}"

    test_directory ${EVAL_DIR}

    local FILE_COUNT=$(hadoop fs -count ${EVAL_DIR} | awk '{ print $2 }')

    info_log "CURRENT DATA IN THE GCP ENV: is ${FILE_COUNT}"

    if [ ${FILE_COUNT} -ne 0 ]; then

        info_log "CLOUD STORAGE DIRECTORY BEING DELETED: is ${EVAL_DIR}"

        hadoop fs -rm -skipTrash -r -f ${CLOUD_STORAGE_DIR}

    else

        warn_log "${EVAL_DIR} previous export file count is zero skipping the delete"

    fi

}

#Main Program
function main() {

    info_log "Google Cloud Storage detele process started: ${0}"

    info_log "Google Cloud Storage deleting object in path ${GCS_OBJECT_PATH}"

    cloud_exportdirectory_load ${GCS_OBJECT_PATH}

}

#Execution Program
prepare_shell_jar_log_file

main 2>&1 | tee -a ${shell_jar_log_file}

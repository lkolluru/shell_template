#!/bin/bash

source "/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/onb/config/onb_env.sh"
source "/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/onb/scripts/bash/core/step_shell.sh"
source "/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/onb/scripts/bash/core/filehandler_shell.sh"
set -euo pipefail
set -o errtrace
trap 'gen_shell_jar_error ${LINENO} ${?}' ERR

#functions --up for deprication and consolidation into the generic jar.
#######################################
# Cloud Strorage hdfs Handler Functions Repository Module
# Cloud Storage hdfs Modules:
#   cloud_exportdirectory_load

#######################################
function cloud_exportdirectory_load() {

    [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least one argument is required" && return 1

    local CLOUD_STORAGE_DIR="${1}"
    #local EVAL_DIR="$(echo "${1}" | sed 's/\*//g')"
    local EVAL_DIR
    local FILE_COUNT
    EVAL_DIR="${1//\*/}"

    info_log "${FUNCNAME[0]}: CLOUD STORAGE DIRECTORY BEING EVALUATED: is ${EVAL_DIR}"

    test_directory_cloud "${EVAL_DIR}"

    FILE_COUNT=$(hadoop fs -count "${EVAL_DIR}" | awk '{ print $2 }')

    info_log "CURRENT DATA IN THE GCP ENV: is ${FILE_COUNT}"

    if [ "${FILE_COUNT}" -ne 0 ]; then

        info_log "CLOUD STORAGE DIRECTORY BEING DELETED: is ${EVAL_DIR}"

        hadoop fs -rm -skipTrash -r -f "${CLOUD_STORAGE_DIR}"

    else

        warn_log "${EVAL_DIR} previous export file count is zero skipping the delete"

    fi

}

#Main Program
function main() {

    info_log "Google Cloud Storage detele process started: ${0}"

    info_log "Google Cloud Storage deleting object in path ${GCS_OBJECT_PATH}"

    cloud_exportdirectory_load "${GCS_OBJECT_PATH}"

}

#Execution Program
prepare_shell_jar_log_file

main 2>&1 | tee -a "${shell_jar_log_file}"

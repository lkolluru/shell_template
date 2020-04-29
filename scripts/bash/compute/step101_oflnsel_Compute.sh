#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Functions

function gen_jar_execution() {

    [ $# -ne 6 ] && error_log "$FUNCNAME: at least 6 arguments are required" && return 1

    CALCENGINE_JAR_VER_NAME=$1
    LIBJARS=$2
    JAR_ENV=$3
    JAR_FG=$4
    JAR_RESOURCES=$5
    PWD_FILE_RES=$6
    info_log "$FUNCNAME:code execution directory ${JAR_DIRECTORY}"
    info_log "$FUNCNAME:jar execution version ${CALCENGINE_JAR_VER_NAME}"
    info_log "$FUNCNAME:jar resources info ${JAR_RESOURCES}"
    info_log "$FUNCNAME:password file resources info ${PWD_FILE_RES}"

    hadoop jar ${CALCENGINE_JAR_VER_NAME} com.pch.hdlCalcEngine.StandaloneCalcEngine -libjars ${LIBJARS} ${JAR_ENV} ${JAR_FG} ${JAR_RESOURCES} ${PWD_FILE_RES}
    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) failed to execute successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: jar execution compelted successfully for ${JAR_FG}" && return 0
}

#Setup new or edit log file.
prepare_log_file

main() {

    info_log "$FUNCNAME:Command executed: ${0}"

    cd ${JAR_DIRECTORY}

    if ! gen_jar_execution ${CALCENGINE_JAR_VER_NAME} ${LIBJARS} ${JAR_ENV} ${JAR_FG} ${JAR_RESOURCES} ${PWD_FILE_RES}; then 

    exit 1 

    fi 
    
}

main 2>&1 | tee -a ${step_log_file}

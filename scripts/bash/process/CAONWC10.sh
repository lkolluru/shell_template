#!/bin/bash
#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source "/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/onb/config/onb_env.sh"
source "${PROCESS_SHELL_TEMPLATE_SCRIPT}"
source "${ARCHIVE_LOG_SHELL}"
source "${FILE_HANDLER_SCRIPT}"
trap cleanup SIGINT SIGHUP SIGTERM EXIT
trap 'gen_prss_error ${LINENO} ${?}' ERR

#Functions

#######################################
# ONB Process Functions Repository Module
# Process Modules:
#   runModule -- evaluate the steps files and execute the steps
#   run_archive_logs -- evaluate all the previous executions and archive the required logs
#   main -- evaluate all the previous executions and archive the required logs
#   preproces -- evaluate all the previous executions and archive the required logs
#######################################

function runModule() {

        if ! test_path "${PROJ_STEPS_RUNFILE_COMPUTE}"; then
                return 1
        fi

        mapfile -t compute_file_items <"${PROJ_STEPS_RUNFILE_COMPUTE}"

        for line in "${compute_file_items[@]}"; do

                cmnt=$(echo "$line" | awk '{ print substr($1,0,1) }') #check whether step commented

                if [ "$cmnt" == "#" ]; then

                        info_log "${FUNCNAME[0]}:Skipping the step $line\n"
                        continue

                elif [ "$cmnt" == "" ]; then

                        info_log "${FUNCNAME[0]}:Skipping empty line\n"

                else

                        step_name="${PROJ_BASH_COMPUTE_DIR}/${line}"

                        if ! test_path "${step_name}"; then
                                return 1
                        fi

                        bash "${PROJ_BASH_COMPUTE_DIR}/${line}"

                        subprocess_return_code=$?

                        [ ${subprocess_return_code} -ne 0 ] && fatal_log "${FUNCNAME[0]}: ${step_name} failed with a error code from the step shell with ${subprocess_return_code}" && exit ${subprocess_return_code}

                        [ ${subprocess_return_code} -eq 0 ] && info_log "${FUNCNAME[0]}: ${step_name} completed successfully with ${subprocess_return_code}"

                        unset step_name

                fi

        done

}

function run_archive_logs() {

        if ! test_path "${ARCHIVE_LOG_SHELL}"; then
                return 1
        fi

        info_log "${FUNCNAME[0]}:evaluation of the log directories for  ${ARCHIVE_LOG_DIRECTORY} started"

        if ! eval_archivedirectory "${ARCHIVE_LOG_DIRECTORY}"; then

                return 1

        fi

        info_log "${FUNCNAME[0]}:archival of the logs in the directories for ${ACTIVE_LOG_DIRECTORY} started"

        if ! process_archivelogs "${ACTIVE_LOG_DIRECTORY}" "${ARCHIVE_LOG_DIRECTORY}"; then
                return 1
        fi

        info_log "${FUNCNAME[0]}:evaludation and archival of the logs in the directories for ${ARCHIVE_LOG_DIRECTORY} completed" && return 0

}

function preproces() {

        info_log "${FUNCNAME[0]}:Archive logs for previous execution triggerred from : ${0}"

        run_archive_logs

        preproces_rc=$?

        if [ $preproces_rc -ne 0 ]; then

                fatal_log "${FUNCNAME[0]}:unable to complete successfully failing the process failing with $preproces_rc"
                return 1
        else
                return ${preproces_rc}
        fi

}

function main() {

        export HADOOP_USER_CLASSPATH_FIRST=true

        info_log "${FUNCNAME[0]}:Command executed: ${0}"

        runModule

        main_rc=$?

        if [ $main_rc -ne 0 ]; then

                fatal_log "${FUNCNAME[0]}:unable to complete successfully failing the process"
                exit ${main_rc}

        else
                return ${main_rc}
        fi
}

#Main Program

## Code Initalization and Cleanup Logging Process
prepare_archivelog_file
preproces 2>&1 | tee -a "${archivelog_file}" ##bash bug exit codes maked in the pipes.
[ "${PIPESTATUS[0]}" -ne 0 ] && exit 254

## OFLNSEL Main Compute Process
prepare_log_file
main 2>&1 | tee -a "${log_file}"

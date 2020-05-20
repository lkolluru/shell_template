#!/bin/bash

set -uo pipefail
set -o errtrace
source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/$1/onb/config/onb_env.sh
source ${PROCESS_SHELL_TEMPLATE_SCRIPT}
trap cleanup SIGINT SIGHUP SIGTERM EXIT
trap 'gen_prss_error ${LINENO} ${?}' ERR

#Functions this is the main function which executes each step in RUNFILE

function runModule() {
        cat "${PROJ_STEPS_RUNFILE_PTP_MERKLEHH_EXPORT}" |
                while read line; do
                        cmnt=$(echo $line | awk '{ print substr($1,0,1) }') #check whether step commented
                        if [ "$cmnt" == "#" ]; then
                                info_log "Skipping the step $line\n"
                                continue
                        elif [ "$cmnt" == "" ]; then
                                info_log "Skipping empty line\n"
                        else
                                if [ -e "${PROJ_BASH_POSTSCORING_DIR}/${line}" ]; then #check for step shell name existence
                                        bash "${PROJ_BASH_POSTSCORING_DIR}/${line}"
                                else
                                        error_log "${PROJ_BASH_POSTSCORING_DIR}/${line} doesn't seem to exists\n"
                                        touch $temp_touch_file
                                        send_mainscript_failure_email
                                        exit 1
                                fi
                        fi
                done
}

function main() {

        info_log "Command executed: ${0}"

        temp_touch_file="${log_directory}/tmp_status_$(date +"%Y_%m_%d_%H_%M_%S")"

        runModule

}

#Main Program

return_exit_code=0

#Setup new or edit log file.
prepare_log_file

#this touch file to trigger success email only after completion of all steps
#temp_touch_file="${log_directory}/tmp_status_$(date +"%Y_%m_%d_%H_%M_%S")"
#info_log "Command executed: ${0}" 2>&1 | tee -a ${log_file}

export HADOOP_USER_CLASSPATH_FIRST=true

main 2>&1 | tee -a ${log_file}
#Send success email otherwise exit
#if [ "$?" == "0" ]; then
#        runModule 2>&1 | tee -a ${log_file}
#else
#       error_log "Reporting Aquireapp process Failed" 2>&1 | tee -a ${log_file}
#        exit 1
#fi

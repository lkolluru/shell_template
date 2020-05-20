#!/bin/bash 

set -uo pipefail
set -E
set -o errtrace
source "/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/onb/config/onb_env.sh"
source "${PROCESS_SHELL_TEMPLATE_SCRIPT}"
source "${ARCHIVE_LOG_SHELL}"
source "${FILE_HANDLER_SCRIPT}"
trap cleanup SIGINT SIGHUP SIGTERM EXIT
trap 'gen_prss_error ${LINENO} ${?}' ERR


#######################################
# ONB Process Functions Repository Module
# Process Modules:
#   runModule 
#   main 
#######################################

function runModule() {

        if ! test_path "${PROJ_STEPS_RUNFILE_PTE_MERKLEZIP_EXPORT}"; then
                return 1
        fi

        mapfile -t export_file_items <"${PROJ_STEPS_RUNFILE_PTE_MERKLEZIP_EXPORT}"

        for line in "${export_file_items[@]}"; do

                cmnt=$(echo "$line" | awk '{ print substr($1,0,1) }') #check whether step commented

                if [ "$cmnt" == "#" ]; then

                        info_log "${FUNCNAME[0]}:Skipping the step $line\n"
                        continue

                elif [ "$cmnt" == "" ]; then

                        info_log "${FUNCNAME[0]}:Skipping empty line\n"

                else

                        step_name="${PROJ_BASH_POSTSCORING_DIR}/${line}"

                        if ! test_path "${step_name}"; then
                                return 1
                        fi

                        bash "${PROJ_BASH_POSTSCORING_DIR}/${line}"

                        subprocess_return_code=$?

                        [ ${subprocess_return_code} -ne 0 ] && fatal_log "${FUNCNAME[0]}: ${step_name} failed with a error code from the step shell with ${subprocess_return_code}" && exit ${subprocess_return_code}

                        [ ${subprocess_return_code} -eq 0 ] && info_log "${FUNCNAME[0]}: ${step_name} completed successfully with ${subprocess_return_code}"

                        unset step_name

                fi

        done

}

function main() {

        export HADOOP_USER_CLASSPATH_FIRST=true

        info_log "${FUNCNAME[0]}:Command executed: ${0}"

        runModule

        main_return_code=$?

        [ $main_return_code -ne 0 ] && fatal_log "${FUNCNAME[0]}:unable to complete successfully failing the process" && exit ${main_return_code}

        return ${main_return_code}

}

#Main Program

prepare_log_file

main 2>&1 | tee -a "${log_file}"
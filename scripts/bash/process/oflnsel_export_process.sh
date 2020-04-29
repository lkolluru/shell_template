#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
#######################################
# OFLNSEL WORKFLOW RE_DIRECT Repository Module
# Process Modules:
#   main -- evaluate the steps files and execute the steps
#   test1 -- evaluate all the previous executions and archive the required logs
#   test2 -- evaluate all the previous executions and archive the required logs
#######################################
case ${2} in
main)
   source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/config/oflnsel_env.sh
   ;;
test1)
   source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/config/oflnsel_env_test1.sh
   ;;
test2)
   source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/${1}/oflnsel/config/oflnsel_env_test2.sh
   ;;
*)
   exit 1
   ;;
esac

source ${PROCESS_SHELL_TEMPLATE_SCRIPT}
source ${ARCHIVE_LOG_SHELL}
source ${FILE_HANDLER_SCRIPT}
trap cleanup SIGINT SIGHUP SIGTERM EXIT
trap 'gen_prss_error ${LINENO} ${?}' ERR


#######################################
# OFLNSEL Process Functions Repository Module
# Process Modules:
#   runModule 
#   main 
#######################################

function runModule() {

        if ! test_path ${PROJ_STEPS_RUNFILE_EXPORT}; then
                return 1
        fi

        mapfile -t export_file_items <${PROJ_STEPS_RUNFILE_EXPORT}

        for line in ${export_file_items[@]}; do

                cmnt=$(echo $line | awk '{ print substr($1,0,1) }') #check whether step commented

                if [ "$cmnt" == "#" ]; then

                        info_log "$FUNCNAME:Skipping the step $line\n"
                        continue

                elif [ "$cmnt" == "" ]; then

                        info_log "$FUNCNAME:Skipping empty line\n"

                else

                        step_name="${PROJ_BASH_IMPORT_DIR}/${line}"

                        if ! test_path ${step_name}; then
                                return 1
                        fi

                        bash "${PROJ_BASH_IMPORT_DIR}/${line}"

                        subprocess_return_code=$?

                        [ ${subprocess_return_code} -ne 0 ] && fatal_log "$FUNCNAME: ${step_name} failed with a error code from the step shell with ${subprocess_return_code}" && exit 1

                        [ ${subprocess_return_code} -eq 0 ] && info_log "$FUNCNAME: ${step_name} completed successfully with ${subprocess_return_code}"

                        unset step_name

                fi

        done

}

function main() {

        export HADOOP_USER_CLASSPATH_FIRST=true

        info_log "$FUNCNAME:Command executed: ${0}"

        runModule

        main_return_code=$?

        [ $main_return_code -ne 0 ] && fatal_log "$FUNCNAME:unable to complete successfully failing the process" && exit ${main_return_code}

        return ${main_return_code}

}

#Main Program

prepare_log_file

main 2>&1 | tee -a ${log_file}
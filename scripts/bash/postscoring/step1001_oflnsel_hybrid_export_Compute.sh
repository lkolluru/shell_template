#!/bin/bash

#Set Global Variables
set -e
set -u
set -o pipefail
source ${STEP_SHELL_TEMPLATE_SCRIPT}

#Functions

trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap send_failure_email ERR

#Main Program

#CHANGE FOLLOWING VARIABLES ACCORDING TO ENV
return_exit_code=0

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

cd ${JAR_DIRECTORY}

info_log "code execution directory" ${JAR_DIRECTORY} 2>&1 | tee -a ${step_log_file}
info_log "jar execution version" ${CALCENGINE_JAR_VER_NAME} 2>&1 | tee -a ${step_log_file}
info_log "jar resources info"${JAR_RESOURCES} 2>&1 | tee -a ${step_log_file}
#hdlCalcEngine_template_r1.0.jar
hadoop jar ${CALCENGINE_JAR_VER_NAME} com.pch.hdlCalcEngine.StandaloneCalcEngine -libjars ${LIBJARS} ${JAR_ENV} ${HYBRID_EXPORT_JAR_FG} ${JAR_RESOURCES} ${PWD_FILE_RES} 2>&1 | tee -a ${step_log_file}

return_exit_code=$?
error_log " Error code from Calcengine: ${return_exit_code}" 2>&1 | tee -a ${step_log_file}

exit $return_exit_code

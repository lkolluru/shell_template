#!/bin/bash

#Set Global Variables
set -e
set -u
set -o pipefail
source ${STEP_SHELL_TEMPLATE_SCRIPT}
#Functions
#parentdir=/mapr/pchmaprclt01.prod.pch.com/CM/HDLP/Common/UAT/Scripts/oflnsel/scripts/bash/postscoring/
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap send_failure_email ERR

#Main Program
return_exit_code=0

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

sh "$PROJ_BASH_CORE_DIR"/oflnsel_prezip_hdp_transfer.sh modsro

return_exit_code=$?
error_log " Error code from Calcengine: ${return_exit_code}" 2>&1 | tee -a ${step_log_file}

exit $return_exit_code

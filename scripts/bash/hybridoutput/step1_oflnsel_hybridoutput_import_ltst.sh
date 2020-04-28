 #!/bin/bash 

#Set Global Variables
set -e;
set -u;
set -o pipefail;
source ${STEP_SHELL_TEMPLATE_SCRIPT} ;

trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap send_failure_email ERR

#Main Program

#CHANGE FOLLOWING VARIABLES ACCORDING TO ENV
export HIVE_SHELLFILE_NM=$(basename ${0});

#Setup new or edit log file.
prepare_log_file;

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

hiveQueryExec ${PROJ_HIVE_HYBRID_COMPUTE_DIR}


exit $?  ;


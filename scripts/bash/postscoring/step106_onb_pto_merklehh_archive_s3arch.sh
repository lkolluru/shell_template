#!/bin/bash

#Set Global Variables
set -o pipefail
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Functions

function runArchive() {

   if [[ -e ${ARCHIVE_TABLES_PTO_MERKLEHH_EXPORT_FILE} && -e ${CE_HDLP_S3ARCHIVE_SCRIPT} ]]; then
      cat ${ARCHIVE_TABLES_PTO_MERKLEHH_EXPORT_FILE} |
         while read line; do
            cmnt=$(echo $line | awk '{ print substr($1,0,1) }') #check whether step commented
            if [ "$cmnt" == "#" ]; then
               info_log "Skipping the archive step $line\n"
               continue
            elif [ "$cmnt" == "" ]; then
               info_log "Skipping empty line\n"
            else
               info_log "proceeding with archiving  ${line}"
               bash ${CE_HDLP_S3ARCHIVE_SCRIPT} ${line}
            fi
         done
   else

      fatal_log "one of the control files does not exist ${ARCHIVE_TABLES_PTO_MERKLEHH_EXPORT_FILE},${CE_HDLP_S3ARCHIVE_SCRIPT} does not exist"
      exit 1

   fi

}

#Main Program

#CHANGE FOLLOWING VARIABLES ACCORDING TO ENV
return_exit_code=0
#export HDL_ROOT_DIRECTORY_REGEX;
export SA_DEST_DIR
export IM_DEST_DIR
export CM_DEST_DIR
export ARCHIVE_DATE

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

runArchive 2>&1 | tee -a ${step_log_file}


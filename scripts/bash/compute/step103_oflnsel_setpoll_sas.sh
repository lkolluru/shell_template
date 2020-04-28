#!/bin/bash
#Set Global Variables
set -o pipefail
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Functions

function setPoll2SAS() {

   if [[ -e ${AGG_EXPORT_ITEMS_FILE} && -e ${POLL2SAS_SCRIPT} ]]; then

      cat ${AGG_EXPORT_ITEMS_FILE} |
         while read line; do
            cmnt=$(echo $line | awk '{ print substr($1,0,1) }') #check whether step commented or not.
            if [ "$cmnt" == "#" ]; then

               info_log "Skipping the Poll setting for the item: $line\n"
               continue

            elif [ "$cmnt" == "" ]; then

               info_log "Skipping empty line\n"

            else

               info_log "proceeding with Poll setting for  ${line}"
               bash ${POLL2SAS_SCRIPT} ${line}

            fi
         done
   else

      fatal_log "one of the control files does not exist ${AGG_EXPORT_ITEMS_FILE} does not exist"
      exit 1

   fi

}

#Main Program

#CHANGE FOLLOWING VARIABLES ACCORDING TO ENV
return_exit_code=0

#Setup new or edit log file.
prepare_log_file

info_log "Command executed: ${0}" 2>&1 | tee -a ${step_log_file}

setPoll2SAS 2>&1 | tee -a ${step_log_file}

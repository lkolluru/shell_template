#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${CE_HDLP_S3ARCHIVE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Functions

function runArchive() {

   if ! test_path ${ARCHIVE_TABLES_FILE}; then

      return 1

   fi

   mapfile -t cloud_archive_items <${ARCHIVE_TABLES_FILE}

   for cloud_archive_item in ${cloud_archive_items[@]}; do

      cmnt=$(echo ${cloud_archive_item} | awk '{ print substr($1,0,1) }') #check whether step commented

      if [ "${cmnt}" == "#" ]; then

         info_log "$FUNCNAME:Skipping the commented step ${cloud_archive_item}\n"

         continue

      elif [ "$cmnt" == "" ]; then

         info_log "$FUNCNAME:Skipping empty line\n"

      else

         info_log "$FUNCNAME:proceeding with archivin ${cloud_archive_item}"

         gcp_consolidated_archive_push "${cloud_archive_item}"

         gcp_consolidated_archive_push_ret_code=$?

         if [ $gcp_consolidated_archive_push_ret_code -ne 0 ]; then  

         return 1
         
         fi 

      fi

   done
   
   return 0 

}

#Main Program

function main() {

   #export HDL_ROOT_DIRECTORY_REGEX;
   export SA_DEST_DIR
   export IM_DEST_DIR
   export CM_DEST_DIR
   export ARCHIVE_DATE

   #Setup new or edit log file.

   info_log "$FUNCNAME:Command executed: ${0}"

   if ! runArchive; then
      
      error_log "$FUNCNAME: run archive failed"
      exit 1

   fi

   return 0

}

prepare_log_file

main 2>&1 | tee -a ${step_log_file}

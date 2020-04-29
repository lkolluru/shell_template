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
#this is a file watcher to check sas scoring files arrived
#sends email when file available and also sends email if the file not arrived at 12 PM
function checkTrigFile() {

   trap send_mainscript_failure_email ERR

   if [ $(ls "$FILE_WATCH_EXPORT_READY_DIR" | wc -l) != "0" ]; then

      info_log "below is the files on import trigger dir ${FILE_WATCH_EXPORT_READY_DIR} "
      ls -ltr "${FILE_WATCH_EXPORT_READY_DIR}"
      info_log "$(ls ${FILE_WATCH_EXPORT_READY_DIR})"

      if [ $(ls "$FILE_WATCH_EXPORT_READY_DIR" | wc -l) != "1" ]; then
         error_log "there are two or more trigger files"
         mail -s "${email_subject_env}: ${log_subject_area}: ATTENTION - More than one trigger file" ${failure_to_email} <<<"Please check. There are two or more trigger files. Triggers  are at $FILE_WATCH_EXPORT_READY_DIR"
         mail -v -r noreply@pch.com -s "${email_subject_env}: ${log_subject_area}: ATTENTION - More than one trigger file" ${to_phone} <<<"Please check. There are two or more trigger files. Triggers  are at $FILE_WATCH_EXPORT_READY_DIR"
         exit 1
      fi

      SAS_SCORING_FILE_NM=$(ls $FILE_WATCH_EXPORT_READY_DIR)
      info_log "scoring file: $SAS_SCORING_FILE_NM  received.  Sending email & proceeding with process"
      mail -s "${email_subject_env}: ${log_subject_area}: RECEIVED - SAS scoring  Files" -a "$FILE_WATCH_EXPORT_READY_DIR/$SAS_SCORING_FILE_NM" ${success_to_email} <<<"Proceeding with ${log_subject_area}  export  processing"
      mail -v -r noreply@pch.com -s "${email_subject_env}: ${log_subject_area}: RECEIVED - SAS scoring Files" ${to_phone} <<<"Proceeding with ${log_subject_area}  export  processing"
      info_log "moving the trig file from  ${FILE_WATCH_EXPORT_READY_DIR} to ${FILE_WATCH_EXPORT_COMPLETE_DIR} "
      mv -f ${FILE_WATCH_EXPORT_READY_DIR}/oflnsel_export_trigger* ${FILE_WATCH_EXPORT_COMPLETE_DIR}

   fi

}

#this is the main function which executes each step in RUNFILE
function runModule() {
   cat "${PROJ_STEPS_RUNFILE_EXPORT}" |
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
               info_log "${PROJ_BASH_POSTSCORING_DIR}/${line} doesn't seem to exists\n"
               touch $temp_touch_file
               send_mainscript_failure_email
               break
            fi
         fi
      done
}

trap cleanup SIGINT SIGHUP SIGTERM EXIT

#Main Program

return_exit_code=0

#Setup new or edit cron log file.
prepare_cronlog_file
#this touch file to trigger success email only after completion of all steps
temp_touch_file="${log_directory}/tmp_status_$(date +"%Y_%m_%d_%H_%M_%S")"

info_log "Command executed: ${0}" 2>&1 | tee -a ${log_file}

#checking SAS file scoring

## Enable this as this checks for the ready file  and moves it to the completed this is very essential for the workflow
## test this incrontab feature out.
checkTrigFile

#Send success email otherwise exit
if [ "$?" == "0" ]; then
   info_log "dependency objects: for mainframe export process received.  Sending email & proceeding with process" 2>&1 | tee -a ${log_file}
   runModule 2>&1 | tee -a ${log_file}
   if [ "$?"="0" ] && [ ! -e "$temp_touch_file" ]; then
      send_success_email
   fi

else
   info_log "dependency objects: for Scoring process is yet to received.  Sending email & existing the application" 2>&1 | tee -a ${log_file}
   exit 1

fi

exit

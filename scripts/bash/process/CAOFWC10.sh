#!/bin/bash

set -euo pipefail
source /mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/codebase/calcengine/$1/oflnsel/config/oflnsel_env.sh
source ${PROCESS_SHELL_TEMPLATE_SCRIPT}

#this is a file watcher to check sas scoring files arrived
#sends email when file available and also sends email if the file not arrived at 12 PM
function checkTrigFile() {

        trap send_mainscript_failure_email ERR

        if [ $(ls "$FILE_WATCH_IMPORT_READY_DIR" | wc -l) != "0" ]; then
                info_log "below is the files on import trigger dir ${FILE_WATCH_IMPORT_READY_DIR} "
                ls -ltr "${FILE_WATCH_IMPORT_READY_DIR}"
                info_log "$(ls ${FILE_WATCH_IMPORT_READY_DIR})"
                if [ $(ls "$FILE_WATCH_IMPORT_READY_DIR" | wc -l) != "1" ]; then
                        error_log "there are two or more trigger files"
                        mail -s "${email_subject_env}: ${log_subject_area}: ATTENTION - More than one trigger file" ${failure_to_email} <<<"Please check. There are two or more trigger files. Triggers  are at $FILE_WATCH_IMPORT_READY_DIR"
                        mail -v -r noreply@pch.com -s "${email_subject_env}: ${log_subject_area}: ATTENTION - More than one trigger files for Import" ${to_phone} <<<"Please check. There are two or more trigger files. Triggers  are at $FILE_WATCH_IMPORT_READY_DIR"
                        exit 1
                fi

                SAS_SCORING_FILE_NM=$(ls $FILE_WATCH_IMPORT_READY_DIR)
                info_log "scoring file: $SAS_SCORING_FILE_NM  received.  Sending email & proceeding with process"
                mail -s "${email_subject_env}: ${log_subject_area} : RECEIVED - COMPUTE Files" -a "$FILE_WATCH_IMPORT_READY_DIR/$SAS_SCORING_FILE_NM" ${success_to_email} <<<"Proceeding with ${log_subject_area} import &  compute  processing"
                mail -v -r noreply@pch.com -s "${email_subject_env}: RECEIVED - Import Files" ${to_phone} <<<"Proceeding with ${log_subject_area} import &  compute  processing"
                info_log "moving the trig file from  ${FILE_WATCH_IMPORT_READY_DIR} to ${FILE_WATCH_IMPORT_COMPLETE_DIR} "
                mv -f ${FILE_WATCH_IMPORT_READY_DIR}/oflnsel_import_trigger* ${FILE_WATCH_IMPORT_COMPLETE_DIR}

        fi

}

#this is the main function which executes each step in RUNFILE
function runModule() {
        cat "${PROJ_STEPS_RUNFILE_COMPUTE}" |
                while read line; do
                        cmnt=$(echo $line | awk '{ print substr($1,0,1) }') #check whether step commented
                        if [ "$cmnt" == "#" ]; then
                                info_log "Skipping the step $line\n"
                                continue
                        elif [ "$cmnt" == "" ]; then
                                info_log "Skipping empty line\n"
                        else
                                if [ -e "${PROJ_BASH_COMPUTE_DIR}/${line}" ]; then #check for step shell name existence
                                        bash "${PROJ_BASH_COMPUTE_DIR}/${line}"
                                else
                                        info_log "${PROJ_BASH_COMPUTE_DIR}/${line} doesn't seem to exists\n"
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

# this touch file to trigger success email only after completion of all steps
# depricated only for legacy used cases.

temp_touch_file="${log_directory}/tmp_status_$(date +"%Y_%m_%d_%H_%M_%S")"

info_log "Command executed: ${0}" 2>&1 | tee -a ${log_file}

#checking SAS file scoring
checkTrigFile
bash ${ARCHIVE_LOG_SHELL}
export HADOOP_USER_CLASSPATH_FIRST=true
#Send success email otherwise exit
if [ "$?" == "0" ]; then
        info_log "dependency objects: for mainframe process received.  Sending email & proceeding with process" 2>&1 | tee -a ${log_file}
        runModule 2>&1 | tee -a ${log_file}
        if [ "$?"="0" ] && [ ! -e "$temp_touch_file" ]; then
                send_success_email
        fi

else
        info_log "dependency objects: for mainframe process is yet to received.  Sending email & existing the application" 2>&1 | tee -a ${log_file}
        exit 1
fi

exit

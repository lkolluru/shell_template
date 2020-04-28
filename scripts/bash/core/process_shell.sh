#!/bin/bash

#Functions

#######################################
# Logging Functions Repository Module
# Log Modules:
#   info_log
#   warn_log
#   error_log
#   fatal_log
#   generic_log_message

#######################################
function generic_log_message() {
        echo $(date), $(basename ${0})
}

function info_log() {

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

        _message=${1}
        echo -e $(generic_log_message) "[INFO]:- ${_message}"

}

function warn_log() {

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

        _message=${1}
        echo -e $(generic_log_message) "[WARN]:- ${_message}"

}

function error_log() {

        [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && return 1

        _message=${1}
        echo -e $(generic_log_message) "[ERROR]:- ${_message}"

}

function fatal_log() {

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

        _message=${1}
        echo -e $(generic_log_message) "[FATAL]:- ${_message}"

}

#######################################
# Logging file preparation Functions Repository Module
# Error Handling Modules:
#   prepare_log_file
#   prepare_jar_log_file
#   prepare_shell_jar_log_file

#######################################
function prepare_log_file() {

        log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g')
        log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d").log
        subject_area="${log_subject_area}"

        if [ ! -d $(append_character ${log_directory} "/") ]; then
                fatal_log "Log directory ${log_directory} does not exist."
                return 1
        fi

        if [ -e ${log_file} ]; then
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${log_file}
                info_log "Log file ${log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${log_file}
        else
                touch ${log_file}
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${log_file}
                info_log "Created new ${log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${log_file}
        fi

}

function prepare_cronlog_file() {

        cron_log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g')
        cron_log_file=$(append_character ${cron_log_directory} "/")$(append_character ${cron_log_file_name} "_")$(date +"%Y_%m_%d").log
        subject_area="${log_subject_area}"

        if [[ ! -d $(append_character ${cron_log_directory} "/") ]]; then
                fatal_log "Log directory ${cron_log_directory} does not exist."
                return 1
        fi

        if [[ -e ${cron_log_file} ]]; then
                info_log "----------------------CRON LOG:-------------------------------------------------" 2>&1 | tee -a ${cron_log_file}
                info_log "Log file ${cron_log_file} already exists. Starting new ${subject_area} cron log." 2>&1 | tee -a ${cron_log_file}
        else
                touch ${cron_log_file}
                info_log "----------------------CRON LOG:-------------------------------------------------" 2>&1 | tee -a ${cron_log_file}
                info_log "Created new ${cron_log_file}. Starting new ${subject_area} trigger cron log." 2>&1 | tee -a ${cron_log_file}
        fi

}

function prepare_incronlog_file() {

        incron_log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g')
        incron_log_file=$(append_character ${incron_log_directory} "/")$(append_character ${incron_log_file_name} "_")$(date +"%Y_%m_%d").log
        subject_area="${log_subject_area}"

        if [ ! -d $(append_character ${incron_log_directory} "/") ]; then
                fatal_log "Log directory ${incron_log_directory} does not exist."
                return 1
        fi

        if [ -e ${incron_log_file} ]; then
                info_log "----------------------INCRON LOG:-------------------------------------------------" 2>&1 | tee -a ${incron_log_file}
                info_log "Log file ${incron_log_file} already exists. Starting new ${subject_area} cron log." 2>&1 | tee -a ${incron_log_file}
        else
                touch ${incron_log_file}
                info_log "----------------------INCRON LOG:-------------------------------------------------" 2>&1 | tee -a ${incron_log_file}
                info_log "Created new log file. Starting new ${subject_area} trigger cron log." 2>&1 | tee -a ${incron_log_file}
        fi

}

function prepare_archivelog_file() {

        archivelogdir="/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/application_logs/calcengine/${ENV_FLAG}/oflnsel/archivelogs/archwrkflwlogs"
        log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g')
        archivelog_file=$(append_character ${archivelogdir} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d_%H_%M_%S").log
        subject_area="${log_subject_area}"

        if [ ! -d $(append_character ${archivelogdir} "/") ]; then
                fatal_log "Log directory ${archivelogdir} does not exist."
                return 1
        fi

        if [ -e ${archivelog_file} ]; then
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${archivelog_file}
                info_log "Log file ${archivelog_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${archivelog_file}
        else
                touch ${archivelog_file}
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${archivelog_file}
                info_log "Created new ${archivelog_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${archivelog_file}
        fi

}

#######################################
# Email Functions Repository Module
# Email Modules:
#   send_success_email
#   send_mainscript_failure_email

#######################################
function send_success_email() {

        success_email_subject="COMPLETED: ${email_subject_env} - $(basename ${0}) of ${email_subject_area}."
        success_email_message="$(basename ${0}) of ${email_subject_area} completed successfully at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${log_directory}."
        success_sms_subject="COMPLETED: ${email_subject_env} - $(basename ${0}) for ${email_subject_area}."
        success_sms_message="'$(basename ${0})' completed successfully at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${log_directory}."
        attach_file=$(ls -ltr -t ${log_directory} | grep $(echo $(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        mail -s "${success_email_subject}" -a ${log_directory}/${attach_file} ${success_to_email} <<<"${success_email_message}"
        #mail -v -r noreply@pch.com -s "${success_sms_subject}" ${to_phone} <<< "${success_sms_message}";

}

function send_mainscript_failure_email() {

        error_email_message="Failure of ${email_subject_area}'s Script: '$(basename ${0})'. Attached is the log file. Logs are captured at ${log_directory}."
        error_email_subject="FAILED in ${email_subject_env}:${email_subject_area}'s Script - $(basename ${0}) at $(date +"%Y_%m_%d_%H_%M_%S")."
        error_sms_message="Script Name: $(basename ${0}) Please check error log at "
        error_sms_subject="FAILED in ${email_subject_env}:${email_subject_area}'s Script: $(basename ${0}) ."

        attach_file=$(ls -ltr -t ${log_directory} | grep $(echo $(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        last_line=$(cat ${log_directory}/$attach_file | tail -1)
        mail -s "${error_email_subject}" -a ${log_directory}/${attach_file} ${failure_to_email} <<<"${error_email_message}"
        mail -v -r noreply@pch.com -s "${error_sms_subject}" ${to_phone} <<<"${error_sms_message} ${log_directory}/$attach_file."

}

function send_cron_success_email() {

        success_email_subject="COMPLETED: ${email_subject_env} - $(basename ${0}) of ${email_subject_area}."
        success_email_message="$(basename ${0}) of ${email_subject_area} completed successfully at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${cron_log_directory}."
        success_sms_subject="COMPLETED: ${email_subject_env} - $(basename ${0}) for ${email_subject_area}."
        success_sms_message="'$(basename ${0})' completed successfully at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${cron_log_directory}."
        attach_file=$(ls -ltr -t ${cron_log_directory} | grep $(echo $(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        mail -s "${success_email_subject}" -a ${cron_log_directory}/${attach_file} ${success_to_email} <<<"${success_email_message}"
        #mail -v -r noreply@pch.com -s "${success_sms_subject}" ${to_phone} <<< "${success_sms_message}";

}

function send_cron_mainscript_failure_email() {

        error_email_message="Failure of ${email_subject_area}'s Script: '$(basename ${0})'. Attached is the log file. Logs are captured at ${cron_log_directory}."
        error_email_subject="FAILED in ${email_subject_env}:${email_subject_area}'s Script - $(basename ${0}) at $(date +"%Y_%m_%d_%H_%M_%S")."
        error_sms_message="Script Name: $(basename ${0}) Please check error log at "
        error_sms_subject="FAILED in ${email_subject_env}:${email_subject_area}'s Script: $(basename ${0}) ."

        attach_file=$(ls -ltr -t ${cron_log_directory} | grep $(echo $(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        last_line=$(cat ${cron_log_directory}/$attach_file | tail -1)
        mail -s "${error_email_subject}" -a ${cron_log_directory}/${attach_file} ${failure_to_email} <<<"${error_email_message}"
        #mail -v -r noreply@pch.com -s "${error_sms_subject}" ${to_phone} <<<"${error_sms_message} ${log_directory}/$attach_file."

}

#######################################
# Code Utility Functions Repository Module
# Misc Modules:
#   append_character

#######################################
function append_character() {

        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

        value_passed="${1}"

        character_to_append="${2}"

        if [[ "${value_passed: -1}" != "${character_to_append}" ]]; then

                value_passed=${value_passed}${character_to_append}

        fi

        echo -e ${value_passed}
}

function cron_cleanup() {

        if [ "$?" != "0" ]; then
                error_log "Cron Cleanup function is called to send failure email" 2>&1 | tee -a ${cron_log_file}
                send_cron_mainscript_failure_email
        else
                info_log "Cron Cleanup function is called to send success email" 2>&1 | tee -a ${cron_log_file}
                #send_cron_success_email
        fi
        if [ -e "$temp_touch_file" ]; then
                rm "$temp_touch_file"
        fi
}

function cleanup() {

        return_code=$?

        [ $return_code -eq 0 ] && info_log "$FUNCNAME: $(basename ${0}) completed successfully" 2>&1 | tee -a ${log_file} && send_success_email && exit 0

        [ $return_code -ne 0 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed to complete and exiting with a consolidated exit code ${return_code}" 2>&1 | tee -a ${log_file} && send_mainscript_failure_email && exit 1

}

#######################################
# Error Handling Functions Repository Module
# Error Handling Modules:
#   gen_prss_error
#   gen_cron_prss_error
#   gen_core_error

#######################################
function gen_prss_error() {

        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

        JOB="$0"      # job name
        LASTLINE="$1" # line of error occurrence
        LASTERR="$2"  # error code
        error_log "PROCESS SHELL ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" #2>&1 | tee -a ${log_file}
        #send_failure_email
        return 1

}

function gen_cron_prss_error() {

        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

        JOB="$0"      # job name
        LASTLINE="$1" # line of error occurrence
        LASTERR="$2"  # error code
        error_log "PROCESS SHELL ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" 2>&1 | tee -a ${cron_log_file}
        #send_failure_email
        return 1

}

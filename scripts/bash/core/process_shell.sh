#!/bin/bash

#Functions
#exit 254 reserved for any framework failures
#EXIT 200 reserved for any validation failures to generate appropriate warnings

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

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && exit 254

        _message=${1}
        echo -e $(generic_log_message) "[INFO]:- ${_message}"

}

function warn_log() {

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && exit 254

        _message=${1}
        echo -e $(generic_log_message) "[WARN]:- ${_message}"

}

function error_log() {

        [ $# -eq 0 ] && echo "$FUNCNAME: at least one argument is required" && exit 254

        _message=${1}
        echo -e $(generic_log_message) "[ERROR]:- ${_message}"

}

function fatal_log() {

        [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && exit 254

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

        {
                log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g') &&
                        log_file=$(append_character "${log_directory}" "/")$(append_character "${log_file_name}" "_")$(date +"%Y_%m_%d").log &&
                        subject_area="${log_subject_area}"
        }

        local prepare_log_file_rc=$?

        [ ${prepare_log_file_rc} -ne 0 ] && exit 254

        if [ ! -d $(append_character "${log_directory}" "/") ]; then
                fatal_log "Log directory ${log_directory} does not exist."
                exit 254
        fi

        if [ -e "${log_file}" ]; then
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${log_file}
                info_log "Log file ${log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${log_file}
        else
                touch ${log_file}
                info_log "----------------------APPLICATION LOG:-------------------------------------------------" 2>&1 | tee -a ${log_file}
                info_log "Created new ${log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${log_file}
        fi

        if ! prepare_status_file; then 

                fatal_log "Unable to prepare log file" && exit 254 2>&1 | tee -a ${log_file}
        fi 

}

function prepare_archivelog_file() {

        {
                archivelogdir="/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/application_logs/calcengine/${ENV_FLAG}/${FUNCTIONAL_GROUP}/archivelogs/archwrkflwlogs" &&
                        log_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g') &&
                        archivelog_file=$(append_character ${archivelogdir} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d_%H_%M_%S").log &&
                        subject_area="${log_subject_area}"
        }

        local prepare_archivelog_file_rc=$?

        [ ${prepare_archivelog_file_rc} -ne 0 ] && exit 254

        if [ ! -d $(append_character ${archivelogdir} "/") ]; then
                fatal_log "Log directory ${archivelogdir} does not exist."
                exit 254
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

function prepare_status_file() {

        {
                process_status_file_name=$(echo $(basename ${0}) | sed 's/\.sh//g') &&
                        export process_status_file="${log_directory}/${process_status_file_name}$(date +"%Y_%m_%d").txt"
        }

         prepare_status_file_rc=$?

        [ ${prepare_status_file_rc} -ne 0 ] && exit 254

        if [ ! -e ${process_status_file} ]; then

                touch ${process_status_file}

                echo "step_name","status_code" >${process_status_file}

        fi

}

#######################################
# Email Functions Repository Module
# Email Modules:
#   send_success_email
#   send_mainscript_failure_email
#   send_warning_email

#######################################
function send_success_email() {

        success_email_subject="COMPLETED: ${email_subject_env} - $(basename ${0}) of ${email_subject_area}."
        success_email_message="$(basename ${0}) of ${email_subject_area} completed successfully at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${log_directory}."
        #attach_file=$(ls -ltr -t ${log_directory} | grep $($(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        #attach_file=$(echo ${log_directory}/*$(basename ${0})*/ | sed 's/\.sh//g' | tail -1 | awk -F' ' '{ print $9 }')
        #attach_step_exceution_status=$(ls -ltr ${log_directory}/* | grep '${FUNCTIONAL_GROUP}_status' | tail -1 | awk -F' ' '{ print $9 }')
        #mail -s "${success_email_subject}" -a ${log_directory}/${attach_file} -a ${attach_step_exceution_status} ${success_to_email} <<<"${success_email_message}"
        mail -s "${success_email_subject}" ${success_to_email} <<<"${success_email_message}"

}

function send_mainscript_failure_email() {

        error_email_message="Failure of ${email_subject_area}'s Script: '$(basename ${0})'. Attached is the log file. Logs are captured at ${log_directory}."
        error_email_subject="FAILED in ${email_subject_env}:${email_subject_area}'s Script - $(basename ${0}) at $(date +"%Y_%m_%d_%H_%M_%S")."

        #attach_file=$(ls -ltr -t ${log_directory} | grep $(echo $(basename ${0}) | sed 's/\.sh//g') | tail -1 | awk -F' ' '{ print $9 }')
        #attach_step_exceution_status=$(ls -ltr ${log_directory}/* | grep "${FUNCTIONAL_GROUP}_status" | tail -1 | awk -F' ' '{ print $9 }')
        #echo ${attach_step_exceution_status}
        #last_line=$(cat ${log_directory}/$attach_file | tail -1)
        #mail -s "${error_email_subject}" -a ${log_directory}/${attach_file} -a "${attach_step_exceution_status}" ${failure_to_email} <<<"${error_email_message}"
        mail -s "${error_email_subject}" ${failure_to_email} <<<"${error_email_message}"

}

function send_warning_email() {

        process_file_name=$(echo $(basename ${0}))
        success_email_subject="WARNING: ${email_subject_env} - $(basename ${0}) of ${email_subject_area}."
        success_email_message="$(basename ${0}) of ${email_subject_area} completed with warning at $(date +"%Y_%m_%d_%H_%M_%S"). Logs are at ${log_directory}."
        #attach_file=$(echo ${log_directory}/*$(basename ${0})*/ | sed 's/\.sh//g' | tail -1 | awk -F' ' '{ print $9 }')
        #attach_step_exceution_status=$(ls -ltr ${log_directory}/* | grep "${status_file}" | tail -1 | awk -F' ' '{ print $9 }')
        mail -s "${success_email_subject}" ${success_to_email} <<<"${success_email_message}"
        #-a  ${log_directory}/${attach_file} \
        #-a  ${attach_step_exceution_status} \

}

#######################################
# Code Utility Functions Repository Module
# Misc Modules:
#   append_character

#######################################
function append_character() {

        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && exit 254

        value_passed="${1}"

        character_to_append="${2}"

        if [[ "${value_passed: -1}" != "${character_to_append}" ]]; then

                value_passed=${value_passed}${character_to_append}

        fi

        echo -e ${value_passed}
}

function cleanup() {

        return_code=$?

        [ $return_code -eq 0 ] && info_log "$FUNCNAME: $(basename ${0}) completed successfully" 2>&1 | tee -a ${log_file} && send_success_email && exit 0

        [ $return_code -eq 200 ] && info_log "$FUNCNAME: $(basename ${0}) completed with warnings" 2>&1 | tee -a ${log_file} && send_warning_email && exit 0

        [ $return_code -eq 254 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed with framework errors" && exit $return_code ### can not capture these in the step log files but will be visible from the control M console.

        [ $return_code -ne 0 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed to complete and exiting with a consolidated exit code ${return_code}" 2>&1 | tee -a ${log_file} && send_mainscript_failure_email && exit ${return_code}

}

#######################################
# Error Handling Functions Repository Module
# Error Handling Modules:
#   gen_prss_error full stack trace for the application functions to determine the RC if return traps are enabled.
#   gen_prss_return_handler top caller for the functions.

#######################################

function gen_prss_error() {

        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && exit 254

        local full_trace=${#FUNCNAME[@]}

        for ((i = 1; i < $full_trace; i++)); do
                local func="${FUNCNAME[$i]}"
                local line="${BASH_LINENO[$((i - 1))]}"
                local src="${BASH_SOURCE[$((i - 1))]}"
                printf '%*s' $i '' # indent only for console not the log file
                error_log "GEN PRSS at: $func(), $src, line $line"
        done
}

function gen_prss_return_handler() {

        local func="${FUNCNAME[1]}"
        local line="${BASH_LINENO[0]}"
        local src="${BASH_SOURCE[0]}"
        printf '%*s' 1 ''
        echo "FUNCTION_TRACE:called from: $func(), $src, line $line"
}

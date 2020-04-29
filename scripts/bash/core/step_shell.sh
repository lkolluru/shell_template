#!/bin/bash

#Functions

#source ${CE_HDLP_S3ARCHIVE_SCRIPT}
#source ${FILE_HANDLER_SCRIPT}


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
# Error Handling Functions Repository Module
# Error Handling Modules:
#   gen_shell_jar_error
#   gen_step_error
#   gen_core_error

#######################################

function gen_shell_jar_error() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 3 arguments are required" && return 1

	JOB="$0"      # job name
	LASTLINE="$1" # line of error occurrence
	LASTERR="$2"  # error code
	error_log "$FUNCNAME:GEN JAR SHELL ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" 2>&1 | tee -a ${shell_jar_log_file}

}

function gen_step_error() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

	JOB="$0"      # job name
	LASTLINE="$1" # line of error occurrence
	LASTERR="$2"  # error code
	error_log "$FUNCNAME:STEP ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" 2>&1 | tee -a ${step_log_file}

}

function gen_core_error() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 3 arguments are required" && return 1

	JOB="$0"      # job name
	LASTLINE="$1" # line of error occurrence
	LASTERR="$2"  # error code
	error_log "$FUNCNAME:CORE ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" 2>&1 | tee -a ${step_log_file}

}

#######################################
# Logging file preparation Functions Repository Module
# Error Handling Modules:
#   prepare_log_file
#   prepare_jar_log_file
#   prepare_shell_jar_log_file

#######################################
function prepare_log_file() {

	log_file_name=$($(basename ${0}) | sed 's/\.sh//g')

	step_log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d").log

	subject_area="${log_subject_area}"

	if [ ! -d $(append_character ${log_directory} "/") ]; then

		fatal_log "$FUNCNAME:Log directory ${log_directory} does not exist."

		return 1

	fi

	if [ -e ${step_log_file} ]; then

		info_log "$(basename ${0})::APPLICATION STEP LOG:-------------------------------------------------" 2>&1 | tee -a ${step_log_file}

		info_log "Log file ${step_log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${step_log_file}

	else

		touch ${step_log_file}

		info_log "$(basename ${0})::APPLICATION STEP LOG:-------------------------------------------------" 2>&1 | tee -a ${step_log_file}

		info_log "Created new ${step_log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${step_log_file}

	fi

}

function prepare_jar_log_file() {

	log_file_name=$($(basename ${0}) | sed 's/\.sh//g')

	jar_log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d_%H_%M_%S").log

	subject_area="${log_subject_area}"

	if [ ! -d $(append_character ${log_directory} "/") ]; then

		fatal_log "Log directory ${log_directory} does not exist."

		return 1

	fi

	if [ -e ${jar_log_file} ]; then

		info_log "$(basename ${0})::APPLICATION JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${jar_log_file}

		info_log "Log file ${step_log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${jar_log_file}

	else

		touch ${jar_log_file}

		info_log "$(basename ${0})::APPLICATION JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${jar_log_file}

		info_log "Created new ${step_log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${jar_log_file}

	fi

}

function prepare_shell_jar_log_file() {

	log_file_name=$($(basename ${0}) | sed 's/\.sh//g')

	shell_jar_log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d").log

	subject_area="${log_file_name}"

	if [ ! -d $(append_character ${log_directory} "/") ]; then

		fatal_log "Log directory ${log_directory} does not exist."

		return 1

	fi

	if [ -e ${shell_jar_log_file} ]; then

		info_log "$(basename ${0})::APPLICATION STEP JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${shell_jar_log_file}

		info_log "Log file ${shell_jar_log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${shell_jar_log_file}

	else

		touch ${shell_jar_log_file}

		info_log "$(basename ${0})::APPLICATION STEP JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${shell_jar_log_file}

		info_log "Created new ${shell_jar_log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${shell_jar_log_file}

	fi

}

#######################################
# Code Utility Functions Repository Module
# Misc Modules:
#   clean_up
#   append_character
#   beehive

#######################################

function clean_up() {

	return_code=$?

	status_file="/mapr/JMAPRCLUP01.CLASSIC.PCHAD.COM/application_logs/calcengine/dev/oflnsel/activelogs/steplogs/oflnsel_status.txt"

	echo "$(basename ${0}),${return_code}" >>${status_file}

	[ $return_code -eq 0 ] && info_log "$FUNCNAME: $(basename ${0}) completed successfully" 2>&1 | tee -a ${step_log_file} && exit 0

	[ $return_code -ne 0 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed to complete and exiting with a consolidated exit code 1" 2>&1 | tee -a ${step_log_file} && exit ${return_code}

}

function append_character() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

	value_passed="${1}"

	character_to_append="${2}"

	if [[ "${value_passed: -1}" != "${character_to_append}" ]]; then

		value_passed=${value_passed}${character_to_append}

	fi

	echo -e ${value_passed}
}

function beehive() {

	command -v /opt/mapr/hive/hive-2.3/bin/beeline >/dev/null 2>&1 || {
		error_log "$FUNCNAME: beeline not available"
		return 1
	}

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	local hive_query="${1}"
	local opts="${2:-}"

	info_log "$FUNCNAME:query executing is ${hive_query}"
	info_log "$FUNCNAME:opts for the query are ${opts}"

	/opt/mapr/hive/hive-2.3/bin/beeline \
		--fastConnect=true \
		--silent=true \
		--outputformat=csv2 \
		"${opts}" \
		-u ${jdbc_url} \
		-n ${service_account} \
		-w ${passowrd_file} \
		-e "${hive_query}" 
}

function scoopquery() {

  [ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

  local db_query="${1}"

  info_log "$FUNCNAME:query executing is ${db_query}"

  sqoop eval --connect "${db_jdbc_url}" \
			 --user_name ${db_username} \
			 --passowrd-file ${db_passwordfile} \
  			 --query "${db_query}" 

}

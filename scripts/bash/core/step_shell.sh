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
# Error Handling Functions Repository Module
# Error Handling Modules:
#   gen_shell_jar_error
#   gen_step_error

#######################################

function gen_shell_jar_error() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 3 arguments are required" && return 1

	JOB="$0"      # job name
	LASTLINE="$1" # line of error occurrence
	LASTERR="$2"  # error code
	error_log "$FUNCNAME:GEN JAR SHELL ERROR in ${JOB} : line ${LASTLINE} produced error code ${LASTERR}" 2>&1 | tee -a ${shell_jar_log_file}

}

function gen_step_error() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && exit 254

	local deptn=${#FUNCNAME[@]}

	for ((i = 1; i < $deptn; i++)); do
		local func="${FUNCNAME[$i]}"
		local line="${BASH_LINENO[$((i - 1))]}"
		local src="${BASH_SOURCE[$((i - 1))]}"
		printf '%*s' $i '' # indent only for console not the log file
		error_log "GEN STEP at: $func(), $src, line $line"
	done
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
		log_file_name=$( basename ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]} | sed 's/\.sh//g') &&
			step_log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d").log &&
			subject_area="${log_subject_area}"
	}

	local prepare_log_file_rc=$?

	[ ${prepare_log_file_rc} -ne 0 ] && exit 254

	if [ ! -d $(append_character ${log_directory} "/") ]; then

		fatal_log "$FUNCNAME:Log directory ${log_directory} does not exist."

		return 1

	fi

	if [ -e ${step_log_file} ]; then

		info_log "$FUNCNAME:$(basename ${0})::APPLICATION STEP LOG:-------------------------------------------------" 2>&1 | tee -a ${step_log_file}

		info_log "$FUNCNAME:Log file ${step_log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${step_log_file}

	else

		touch ${step_log_file}

		info_log "$(basename ${0})::APPLICATION STEP LOG:-------------------------------------------------" 2>&1 | tee -a ${step_log_file}

		info_log "$FUNCNAME:Created new ${step_log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${step_log_file}

	fi

}

function prepare_shell_jar_log_file() {

	{
		log_file_name=$(basename ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]} | sed 's/\.sh//g') &&
			shell_jar_log_file=$(append_character ${log_directory} "/")$(append_character ${log_file_name} "_")$(date +"%Y_%m_%d").log &&
			subject_area="${log_file_name}"
	}

	local prepare_shell_jar_log_file_rc=$?

	[ ${prepare_shell_jar_log_file_rc} -ne 0 ] && exit 254

	if [ ! -d $(append_character ${log_directory} "/") ]; then

		fatal_log "$FUNCNAME:Log directory ${log_directory} does not exist."

		return 1

	fi

	if [ -e ${shell_jar_log_file} ]; then

		info_log "$(echo $(basename ${0}))::APPLICATION STEP JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${shell_jar_log_file}

		info_log "$FUNCNAME:Log file ${shell_jar_log_file} already exists. Starting new ${subject_area} process." 2>&1 | tee -a ${shell_jar_log_file}

	else

		touch ${shell_jar_log_file}

		info_log "$(echo $(basename ${0}))::APPLICATION STEP JAR LOG:-------------------------------------------------" 2>&1 | tee -a ${shell_jar_log_file}

		info_log "$FUNCNAME:Created new ${shell_jar_log_file}. Starting new ${subject_area} process." 2>&1 | tee -a ${shell_jar_log_file}

	fi

}

#######################################
# Code Utility Functions Repository Module
# Misc Modules:
#   clean_up -- clear all error traps related to the current shell and nestings from core modules
#   append_character
#   beehive
#   beehivecsv
#   beehivecsvnoheader
#   scoopevalquery
#   scoopimportquery
#   load_consolidated_step_exitcode
#######################################

function clean_up() {

	return_code=$?

	load_consolidated_step_exitcode "$(basename ${0})" "${return_code}"

	[ $return_code -eq 0 ] && info_log "$FUNCNAME: $(basename ${0}) completed successfully" 2>&1 | tee -a ${step_log_file} && exit 0

	[ $return_code -eq 254 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed with framework errors" && exit $return_code ### can not capture these in the step log files but will be visible from the control M console.

	[ $return_code -ne 0 ] && fatal_log "$FUNCNAME: $(basename ${0}) failed to complete and exiting with a consolidated exit code 1" 2>&1 | tee -a ${step_log_file} && exit ${return_code}

}

function append_character() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && exit 254

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
		exit 254
	}

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	local hive_query="${1};"
	#local opts="${2:-}"

	info_log "$FUNCNAME:query executing is ${hive_query}"
	#info_log "$FUNCNAME:opts for the query are ${opts}"

	/opt/mapr/hive/hive-2.3/bin/beeline \
		--fastConnect=true \
		--silent=true \
		--outputformat=csv2 \
		-u ${jdbc_url} \
		-n ${service_account} \
		-w ${passowrd_file} \
		-e "${hive_query}"

	beehive_rc=$?

	[ $beehive_rc -ne 0 ] && error_log "$FUNCNAME:hive query execution failed with exit code" && return 1

	info_log "$FUNCNAME: Sqoop query :${hive_query} is complete" && return 0

}

function beehivecounts() {

	command -v /opt/mapr/hive/hive-2.3/bin/beeline >/dev/null 2>&1 || {
		error_log "$FUNCNAME: beeline not available"
		exit 254
	}

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	local hive_query="${1};"
	#local opts="${2:-}"

	#info_log "$FUNCNAME:query executing is ${hive_query}"
	#info_log "$FUNCNAME:opts for the query are ${opts}"

	/opt/mapr/hive/hive-2.3/bin/beeline \
		--fastConnect=true \
		--silent=true \
		--showHeader=false \
		--outputformat=csv2 \
		-u ${jdbc_url} \
		-n ${service_account} \
		-w ${passowrd_file} \
		-e "${hive_query}"  

	beehive_rc=$?

	if [ $beehive_rc -ne 0 ]; then
		error_log "$FUNCNAME:hive query execution failed with exit code" && return 1
	fi
	#info_log "$FUNCNAME: Sqoop query :${hive_query} is complete" && return 0

}

function beehivecsv() {

	command -v /opt/mapr/hive/hive-2.3/bin/beeline >/dev/null 2>&1 || {
		error_log "$FUNCNAME: beeline not available"
		return 1
	}

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	local hive_query="${1}"
	local hive_csv_destination="${2}"

	info_log "$FUNCNAME:query exporting is ${hive_query}"

	/opt/mapr/hive/hive-2.3/bin/beeline --fastConnect=true --silent=true --showHeader=true --outputformat=csv2 --verbose=false -u ${jdbc_url} -n ${service_account} -w ${passowrd_file} -e "${hive_query}" >>"${hive_csv_destination}"

	beehivecsv_rc=$?

	[ $beehivecsv_rc -ne 0 ] && error_log "$FUNCNAME:hive query execution failed with exit code" && return 1

	info_log "$FUNCNAME: beeline query csv export of:${hive_query} is complete" && return 0

}

function beehivecsvnoheader() {

	command -v /opt/mapr/hive/hive-2.3/bin/beeline >/dev/null 2>&1 || {
		error_log "$FUNCNAME: beeline not available"
		return 1
	}

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	local hive_query="${1}"
	local hive_csv_destination="${2}"

	info_log "$FUNCNAME:query exporting is ${hive_query}"

	/opt/mapr/hive/hive-2.3/bin/beeline --fastConnect=true --silent=true --showHeader=false --outputformat=csv2 --verbose=false -u ${jdbc_url} -n ${service_account} -w ${passowrd_file} -e "${hive_query}" >>"${hive_csv_destination}"

	beehivecsvnoheader_rc=$?

	[ $beehivecsvnoheader_rc -ne 0 ] && error_log "$FUNCNAME:hive query execution failed with exit code" && return 1

	info_log "$FUNCNAME: beeline query csv export of:${hive_query} is complete" && return 0

}

function scoopevalquery() {

	command -v /opt/mapr/sqoop/sqoop-1.4.7/bin/scoop >/dev/null 2>&1 || {
		error_log "$FUNCNAME: scoop not available"
		exit 254
	}

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 arguments are required" && return 1

	local db_query="${1}"
	local sqoop_options_dir="${2}"

	info_log "$FUNCNAME:query executing is ${db_query}"

	export HADOOP_CLASSPATH=/opt/mapr/hadoop/hadoop-2.7.0/share/hadoop/common/lib/

	sqoop --options-file ${sqoop_options_dir} -e "${db_query}" #2>/dev/null

	scoopevalquery_rc=$?

	[ $scoopevalquery_rc -ne 0 ] && error_log "$FUNCNAME:scoop import failed with exit code" && return 1

	info_log "$FUNCNAME: Sqoop query :${db_query} is complete"

}

function scoopimportquery() {

	command -v /opt/mapr/sqoop/sqoop-1.4.7/bin/sqoop >/dev/null 2>&1 || {
		error_log "$FUNCNAME: scoop not available"
		exit 254
	}

	[ $# -ne 3 ] && fatal_log "$FUNCNAME: at least one argument is required" && return 1

	local db_query="${1}"
	local scoop_res_dir="${2}"
	local sqoop_options_file="${3}"

	info_log "$FUNCNAME:Query getting executed from SQL SERVER is :${db_query}"
	info_log "$FUNCNAME:Options file mapreduce job is :${scoop_res_dir}"

	export HADOOP_CLASSPATH=/opt/mapr/hadoop/hadoop-2.7.0/share/hadoop/common/lib/

	#sqoop --options-file ${sqoop_options_file} --append --e "${db_query}" --m 1  --target-dir "${scoop_res_dir}/" >/dev/null
	sqoop --options-file ${sqoop_options_file} --e "${db_query}" --m 1 --delete-target-dir --target-dir "${scoop_res_dir}/" >/dev/null

	scoopimportquery_rc=$?

	[ $scoopimportquery_rc -ne 0 ] && error_log "scoop import failed with exit code" && return 1

	info_log "$FUNCNAME:Sqoop query :${db_query} is complete"

}

function load_consolidated_step_exitcode() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	if [ ! -e $process_status_file ]; then

		error_log "$FUNCNAME: No valid step status file is present" 2>&1 | tee -a ${step_log_file}
		exit 254

	fi

	echo ${1},${2} 2>&1 | tee -a ${process_status_file}

}

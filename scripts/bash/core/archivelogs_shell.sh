#!/bin/bash

#Set Global Variables
source ${PROCESS_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
#Functions

#######################################
# Logging Location cleanup Repository Module
# Log Modules:
#   eval_directory
#   eval_archivedirectory
#   process_archivelogs

#######################################
function eval_directory() {

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	if ! test_directory ${1}; then

		return 1

	fi
}

function eval_archivedirectory() {

	[ $# -eq 0 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	ARCHIVE_LOG_DIR="${1}"

	if ! test_directory ${1}; then

		return 1

	fi

	TODAY_ARCHIVE_DIR=${ARCHIVE_LOG_DIR}/$(date +"%Y%m%d")

	info_log "TODAY_ARCHIVE_DIR: is ${TODAY_ARCHIVE_DIR}"

	if [ -d ${TODAY_ARCHIVE_DIR} ]; then

		info_log "$FUNCNAME:${TODAY_ARCHIVE_DIR} is present for the rundate proceeding with the archival process"

	else

		info_log "$FUNCNAME:${TODAY_ARCHIVE_DIR} is not present creating the directory for the rundate"

		mkdir ${TODAY_ARCHIVE_DIR}

		ret_code_eval_archivedirectory=$?

		[ $ret_code_eval_archivedirectory -ne 0 ] && return 1

	fi

	return 0

}

function process_archivelogs() {

	[ $# -ne 2 ] && error_log "$FUNCNAME: at least one argument is required" && return 1

	LOG_PARENT_DIR="${1}"

	ARCHIVE_PARENT_DIR="${2}"

	info_log "$FUNCNAME: parent folder is LOG_PARENT_DIR: ${LOG_PARENT_DIR}"

	info_log "$FUNCNAME: parent folder is ARCHIVE_PARENT_DIR : ${ARCHIVE_PARENT_DIR}"

	if ! test_directory ${LOG_PARENT_DIR}; then

		return 1
	fi

	if ! test_directory ${ARCHIVE_PARENT_DIR}; then

		return 1

	fi

	info_log "$FUNCNAME: looping folders started in : ${LOG_PARENT_DIR}"

	dir_contents=($(ls -d ${LOG_PARENT_DIR}/*))
	
	for activelogdir in "${dir_contents[@]}"; do

		logdir=${LOG_PARENT_DIR}/"$(basename ${activelogdir})"

		info_log "$FUNCNAME: current logdir for archival is : ${logdir}"

		archivelogdir=${ARCHIVE_PARENT_DIR}/$(date +"%Y%m%d")

		if [ -d ${logdir} ]; then

			logfiles=($(ls ${logdir}))

			for logfile in "${logfiles[@]}"; do

				info_log "$FUNCNAME: $(basename ${logfile}) is the file name"

				if [ "$(basename ${logfile})" == "oflnsel_import_trig_$(date +"%Y_%m_%d").log" ]; then

					info_log "$FUNCNAME: Current Day $logfile skipping the archival to log folder: ${archivelogdir}"

				else

					info_log "$FUNCNAME: moving $logfile to archive log folder: ${archivelogdir}"

					move_item "${logdir}/${logfile}" "${archivelogdir}"

					ret_code_move_item=$?

					[ $ret_code_move_item -ne 0 ] && return 1

				fi

			done

			#putup a empty message if its not there future enhancement.
		else

			error_log "$FUNCNAME: ${logdir} is not a valid directory "

			return 1

		fi

	done
	return 0
}

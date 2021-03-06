#!/bin/bash

source "${STEP_SHELL_TEMPLATE_SCRIPT}"
source "${FILE_HANDLER_SCRIPT}"

#######################################
# Cloud Storage Archival Repository Functions Repository Module
# Repostiory archival Modules:
#   copy_items_gcp
#   test_hivetable
#   add_partition_gcp
#   copy_hdfs_cloud
#   gcp_consolidated_archive_push

#######################################

function copy_items_gcp() {
	: "
                $1=sourcedatadirhdfs
                $2=destinationdirgcp
      "

	[ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

	if [ "$(echo "${2}" | awk '{ print substr($0,length($0)-22,14) }')" == 'archive_date=2' ]; then

		if ! remove_directory_cloud "${2}/"; then
			error_log "${FUNCNAME[0]}:remove_directory_cloud failed " && return 1
		fi

		copy_items_cloud "${1}" "${2}"
		copy_items_cloud_ret_code=$?

		[ $copy_items_cloud_ret_code -ne 0 ] && return 1
		[ $copy_items_cloud_ret_code -eq 0 ] && return 0

	else
		error_log "Destination directory:${2} doesn't look valid; NOT pointing to S3 bucket. Please check Input Dir and environment variables"
		return 1
	fi

}

function test_hivetable() {
	: "
                $1=sourcetablename
      "
	[ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

	local tablename="${1}"

	SHOW_QUERY="SHOW CREATE TABLE ${tablename}"

	[ -z "${SHOW_QUERY}" ] && error_log "${FUNCNAME[0]}:'${SHOW_QUERY}' is empty value failing the process" && return 1

	beehive "${SHOW_QUERY}" >/dev/null

	local test_hivetable_ret_code=$?

	[ $test_hivetable_ret_code -ne 0 ] && return 1

	[ $test_hivetable_ret_code -eq 0 ] && info_log "${FUNCNAME[0]}: input provided is a valid hive table" && return 0

}

function add_partition_gcp() {

	: "
                $1=sourcetablename
				$2=archivedate
      "
	[ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

	PARTITION_QUERY="ALTER TABLE ${1}_S3ARCH ADD IF NOT EXISTS PARTITION (archive_date='${2}')"

	info_log "The CDA historical parition query is as follows ${PARTITION_QUERY}"

	[ -z "${PARTITION_QUERY}" ] && error_log "${FUNCNAME[0]}:${PARTITION_QUERY} is empty value failing the process" && return 1

	if ! test_hivetable "${1}_S3ARCH"; then

		error_log "Archive table not present for this hive table: ${1}"

		return 1

	fi

	if ! beehive "${PARTITION_QUERY}"; then
		return 1
	else
		info_log "${FUNCNAME[0]}:${PARTITION_QUERY} executed and updated table in CDA" && return 0
	fi

}

function copy_hdfs_cloud() {
	: "
                $1=sourcedirectory
      "
	[ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

	case $(echo "$1" | awk '{ print substr($0,2,2) }') in
	sa)
		info_log "${FUNCNAME[0]}: this is to be in SA bucket"

		GCP_ROOT_DIRECTORY=${SA_DEST_DIR}

		DEST_DIR=$(echo "${1}" | sed -r "s;\/${CDA_FILE_REGEX};${GCP_ROOT_DIRECTORY};g")

		[ -z "${DEST_DIR}" ] && error_log "${FUNCNAME[0]}:${1} :produced blank value from hive table" && return 1

		info_log "${FUNCNAME[0]}:${1} :${DEST_DIR} is the cloud storage path"

		if ! copy_items_gcp "${1}" "${DEST_DIR}/archive_date=${ARCHIVE_DATE}"; then

			return 1

		fi

		;;
	im)
		info_log "${FUNCNAME[0]}: this is to be in IM bucket"

		GCP_ROOT_DIRECTORY=${IM_DEST_DIR}

		DEST_DIR=$(echo "${1}" | sed -r "s;\/${CDA_FILE_REGEX};${GCP_ROOT_DIRECTORY};g")

		[ -z "${DEST_DIR}" ] && error_log "${FUNCNAME[0]}:${1} :produced blank value from hive table" && return 1

		info_log "${FUNCNAME[0]}:${1} :${DEST_DIR} is the cloud storage path"

		if ! copy_items_gcp "${1}" "${DEST_DIR}/archive_date=${ARCHIVE_DATE}"; then
			return 1
		fi

		;;
	cm)
		info_log "${FUNCNAME[0]}: this is to be in CM bucket"

		GCP_ROOT_DIRECTORY=${CM_DEST_DIR}

		DEST_DIR=$(echo "${1}" | sed -r "s;\/${CDA_FILE_REGEX};${GCP_ROOT_DIRECTORY};g")

		[ -z "${1}" ] && error_log "${FUNCNAME[0]}:${1} :produced blank value from hive table" && return 1

		info_log "${FUNCNAME[0]}:${1} :${DEST_DIR} is the cloud storage path"

		if ! copy_items_gcp "${1}" "${DEST_DIR}/archive_date=${ARCHIVE_DATE}"; then
			return 1
		fi

		;;
	*)
		error_log "this input:${1} doesn't belong to SA or IM or CM of HDLP CalcEngine. Can not proceed for archive"
		return 1
		;;
	esac
	return 0

}

function gcp_consolidated_archive_push() {

	[ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

	info_log "${FUNCNAME[0]}:input given: ${1}"

	info_log "${FUNCNAME[0]}:the compare regex directory is ${CDA_FILE_REGEX}"

	SRC_ARCH_DIR=$(echo "${1}" | grep -E -o "\/${CDA_FILE_REGEX}.*[^\']") || true

	if [ -n "${SRC_ARCH_DIR}" ]; then

		info_log "${FUNCNAME[0]}:dir copy evaling is  ${SRC_ARCH_DIR}"

		if ! test_directory "${SRC_ARCH_DIR}"; then
			return 1
		fi

		info_log "${FUNCNAME[0]}:copy directory is ${SRC_ARCH_DIR}"

		if ! copy_hdfs_cloud "${SRC_ARCH_DIR}"; then
			return 1
		else
			return 0
		fi

	fi

	info_log "${FUNCNAME[0]}:evaluation complete the vairable provided ${1} is not a directory"

	test_hivetable "${1}"

	check_hive_result_code=$?

	if [ $check_hive_result_code -eq 0 ]; then

		info_log "${FUNCNAME[0]}:this is a hive table: ${1}"

		SHOW_QUERY="SHOW CREATE TABLE"
		SHOW_QUERY+=" ${1}"

		[ -z "${SHOW_QUERY}" ] && error_log "${FUNCNAME[0]}:'${SHOW_QUERY}' is empty value failing the process" && return 1

		SRC_DIR=$(beehive "${SHOW_QUERY}" | grep -E -o "\/${CDA_FILE_REGEX}.*[^\']")

		dir_eval_ret_code=$?

		[ $dir_eval_ret_code -ne 0 ] && return 1

		[ -z "${SRC_DIR}" ] && error_log "${FUNCNAME[0]}:${1} :produced blank value from hive table" && return 1

		info_log "${FUNCNAME[0]}:the compare regex directory is ${SRC_DIR}"

		copy_hdfs_cloud "${SRC_DIR}"

		copy_hdfs_cloud_ret_code=$?

		[ $copy_hdfs_cloud_ret_code -ne 0 ] && error_log "${FUNCNAME[0]}:copy to gcs cloud dir failed" && return 1

		add_partition_gcp "${1}" "${ARCHIVE_DATE}"

		addPartition_ret_code=$?

		[ $addPartition_ret_code -ne 0 ] && error_log "${FUNCNAME[0]}:copy to gcs cloud dir failed" && return 1

		[ $addPartition_ret_code -eq 0 ] && info_log "${FUNCNAME[0]}: gcp_consolidated_archive_push  completed successfully" return 0

	fi

}

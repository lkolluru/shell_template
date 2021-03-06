#!/bin/bash
######################################
# Linux file operations module: EVALUATION FUNCTIONS
#   test_content
#   test_path
#   test_directory
#   test_directory_contents
#   test_directory_cloud
#   test_directory_contents_cloud
#   test_cda_regex
#   test_cda_regex_cloud

#######################################

function test_content() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if [ -s "${1}" ]; then

                info_log "${FUNCNAME[0]}:${1} File has data present"

                return 0

        else
                error_log "${FUNCNAME[0]}:${1} File is empty"

                return 1
        fi

}

function test_path() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if [ -f "${1}" ]; then

                info_log "${FUNCNAME[0]}:Files found in location ${1}"

                return 0

        else
                error_log "${FUNCNAME[0]}:Files not found for processing in location ${1}"

                return 1

        fi

}

function test_directory() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if ! test_cda_regex "${1}"; then
                return 1
        fi

        if hadoop fs -test -d "${1}"; then

                info_log "${FUNCNAME[0]}:${1} directory exists"

                return 0

        else
                error_log "${FUNCNAME[0]}:${1} directory does not exist failing the process"

                return 1
        fi

}

function test_directory_contents() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if ! test_directory "${1}"; then
                return 1
        fi

        count=$(find "${1}" -mindepth 1 -type f | wc -l)
        ##count=$(hadoop fs -ls ${1} | awk '{system("hdfs dfs -count " $6) }')

        [ "${count}" -eq 0 ] && error_log "${FUNCNAME[0]}: directory does not have any contents" && return 1

        [ "${count}" -ne 0 ] && info_log "${FUNCNAME[0]}: directory has ${count} records" && return 0

}

function test_directory_cloud() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        cloud_dir=${1}

        if ! test_cda_regex_cloud "${1}"; then
                return 1
        fi

        if hadoop fs -test -d "${cloud_dir}"; then
                test_dir_return_code=0
        else
                test_dir_return_code=1
        fi

        [ $test_dir_return_code -ne 0 ] && info_log "${FUNCNAME[0]}: directory is not present in the cloud storagedir ${cloud_dir}" && return 1

        [ $test_dir_return_code -eq 0 ] && info_log "${FUNCNAME[0]}: directory is present in the cloud storagedir ${cloud_dir}" && return 0

}

function test_directory_contents_cloud() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if ! test_directory_cloud "${1}"; then
                return 1
        fi

        #count=$(hadoop fs -ls -R "${1}" | grep -E '^-' | wc -l)
        count=$(hadoop fs -ls "${1}" | awk '{system("hdfs dfs -count " $6) }')

        [ "${count}" -eq 0 ] && error_log "${FUNCNAME[0]}: directory does not have any contents" && return 1

        [ "${count}" -ne 0 ] && info_log "${FUNCNAME[0]}: directory has ${count} records" && return 0

}

function test_cda_regex() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        local dir_name=${1}

        cda_folder=$(echo "${dir_name}" | grep -E -o "\/${CDA_FILE_REGEX}.*[^\']") || true ## to handle pipefails parsing is done on the output value

        [ -z "${cda_folder}" ] && fatal_log "${FUNCNAME[0]}: ${dir_name} location is not a valid cda location" && return 1

        [ -n "${cda_folder}" ] && info_log "${FUNCNAME[0]}: ${dir_name} location is a valid cda location" && return 0

}

function test_cda_regex_cloud() {
        : "
                $1=source
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        local dir_name=${1}

        cda_folder=$(echo "${dir_name}" | grep -E -o "\/${CDA_CLOUD_REGEX}.*[^\']") || true

        [ -z "${cda_folder}" ] && [ "${cda_folder}" != " " ] && fatal_log "${FUNCNAME[0]}: ${dir_name} location is not a valid cda location" && return 1

        [ -n "${cda_folder}" ] && [ "${cda_folder}" != " " ] && info_log "${FUNCNAME[0]}: ${dir_name} location is a valid cda location" && return 0
}

######################################
# Linux file operations module: FILE OPERATION FUNCTIONS
#   move_item
#   expand_archive
#   compress_archive
#   copy_item
#   remove_items
#   move_items
#   rename_ftpitem
#######################################

function move_item() {
        : "
                $1=sourcefile
                $2=destinationdir
        "
        [ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least two argument is required" && return 1

        if ! test_path "${1}"; then
                return 1
        fi

        if ! test_directory "${2}"; then
                return 1
        fi

        mv -v "${1}" "${2}"

        move_item_return_code=$?

        if [ $move_item_return_code -ne 0 ]; then

                error_log "${FUNCNAME[0]}:Unable to move objects from ${1} to ${2}"

                return 1
        else

                info_log "${FUNCNAME[0]}:Successfully moved objects from ${1} to ${2}"

                return 0

        fi

}

function expand_archive() {

        : "
                $1=source
                $2=destination
        "
        [ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least 2 argument is required" && return 1

        if ! test_path "${1}"; then
                return 1
        fi

        if ! test_content "${1}"; then
                return 1
        fi

        if ! test_directory "${2}"; then
                return 1
        fi

        tar -xvf "${1}" -C "${2}"

        tar_return_code=$?

        if [ $tar_return_code -ne 0 ]; then

                error_log "${FUNCNAME[0]}:Error. Not able to unzip the file ${1}."

                return 1

        else
                info_log "${FUNCNAME[0]}:Success. Unzipped  ${1} into the location."

                return 0
        fi

}

function compress_archive() {
        : "
                $1=sourcedatadir
                $2=destinationdir
                $3=compressedfilename
        "
        [ $# -ne 3 ] && error_log "${FUNCNAME[0]}: at least 3 argument is required" && return 1

        if ! test_directory_contents "$1"; then
                return 1
        fi

        if ! test_directory "$2"; then
                return 1
        fi

        cd "${2}" && zip -rq -j "${3}" "${1}"

        compress_return_code=$?

        if [ $compress_return_code -ne 0 ]; then

                error_log "${FUNCNAME[0]}:Unable to create the zip file ${3} from the data location ${1}"

                return 1

        else
                info_log "${FUNCNAME[0]}:Successfully created the files compressed file ${3}"

                return 0
        fi

}

function copy_item() {
        : "
                $1=sourcefile
                $2=destinationdir
        "
        [ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least two argument is required" && return 1

        if ! test_path "${1}"; then
                return 1
        fi

        if ! test_directory "${2}"; then
                return 1
        fi

        hadoop fs -cp "${1}" "${2}"

        copy_item_rc=$?

        if [ $copy_item_rc -ne 0 ]; then

                error_log "${FUNCNAME[0]}:Unable to copy objects from ${1} to ${2}"

                return 1
        else

                info_log "${FUNCNAME[0]}:Successfully copied objects from ${1} to ${2}"

                return 0

        fi

}

function remove_items() {

        : "
                $1=sourcedatadir
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        directory=${1}

        if ! test_directory "${1}"; then
                return 1
        fi

        info_log "${FUNCNAME[0]}:${directory} is being evaluated for removal"

        #files=($(hadoop fs -ls "${directory}" | awk '!/^d/ {print $8}'))

        mapfile -t files < <(hadoop fs -ls "${directory}" | awk '!/^d/ {print $8}')
        
        [ ${#files[@]} -eq 0 ] && warn_log "${FUNCNAME[0]}: ${directory} did not generate any records" && return 1

        for file in "${files[@]}"; do

                info_log "${FUNCNAME[0]}:${file} list evaluated for removal"

                if [ -f "${file}" ]; then

                        rm -v "${file}"

                        remove_items_rc=$?

                        if [ $remove_items_rc -ne 0 ]; then

                                error_log "${FUNCNAME[0]}:Unable to remove file from ${file}"

                                return 1
                        fi

                else

                        error_log "${FUNCNAME[0]}:file ${file} not found"

                        return 1

                fi

        done

        return 0

}

function move_items() {

        : "
                $1=sourcedatadir
                $2=destinationdir
        "
        [ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        source_directory="${1}"
        destination_directory="${2}"

        if ! test_directory "${source_directory}"; then
                return 1
        fi

        if ! test_directory "${destination_directory}"; then
                return 1
        fi

        #files=($(hadoop fs -ls "${source_directory}" | awk '!/^d/ {print $8}'))

        mapfile -t files < <(hadoop fs -ls "${source_directory}" | awk '!/^d/ {print $8}')

        [ ${#files[@]} -eq 0 ] && warn_log "${FUNCNAME[0]}: ${source_directory} did not generate any records" && return 1

        for file in "${files[@]}"; do

                info_log "${FUNCNAME[0]}: ${file} file being evaluated for size restrictions prior to movement to dir"

                if [ -s "${file}" ]; then

                        move_item "${file}" "${destination_directory}"
                        move_items_rc=$?

                        [ ${move_items_rc} -ne 0 ] && return 1

                else

                        error_log "${FUNCNAME[0]}:${file} files have empty content"

                        return 1

                fi

        done

        return 0

}

function rename_ftpitem() {

        : "
                $1=sourcedatadir
                $2=destinationdir
                $3=sourcefilename
                $4=renamedfilename
                $5=ftppassword
                $6=ftpservername

        "
        [ $# -ne 6 ] && error_log "${FUNCNAME[0]}: at least 6 argument is required" && return 1

        if ! test_path "${1}"; then
                return 1
        fi

        if [ -z "${2}" ] || [ -z "${3}" ] || [ -z "${4}" ] || [ -z "${5}" ] || [ -z "${6}" ]; then

                error_log "${FUNCNAME[0]}:Blank vairables provided which can not be handled by the sftp process"
                return 1
        fi

        sshpass -p "${5}" sftp "${6}" <<EOF 2>&1 | tee -a "${step_log_file}"
                cd /${2} 
                put ${1}
                rename ${3} ${4}
EOF

        ftp_return_code=${PIPESTATUS[0]}

        if [ "$ftp_return_code" -ne 0 ]; then

                error_log " ${3} File transfer to ${6} failed"
                return 1
        else
                info_log " ${3} File transfer to ${6} successful"
                return 0

        fi

}

function transfer_ftpitem() {
        : "
                $1=ftpip
                $2=ftpuser
                $3=ftppassword
                $4=destinationdir
                $5=sourcefilename
                $6=destinationfilename
        "
        [ $# -ne 6 ] && error_log "${FUNCNAME[0]}: at least 6 argument is required" && return 1

        if ! test_path "${5}"; then
                return 1
        fi

        if [ -z "${2}" ] || [ -z "${3}" ] || [ -z "${4}" ] || [ -z "${1}" ] || [ -z "${6}" ]; then

                error_log "${FUNCNAME[0]}:Blank vairables provided which can not be handled by the ftp process"
                return 1
        fi
        eval "ftp -n -i $1 << END_SCRIPT  2>&1 | tee -a ${step_log_file}
        ascii
        user $2 $3
        cd $4
        put $5 $6
        ls -lt
        quit
        END_SCRIPT"

        ftp_return_code=${PIPESTATUS[0]}

        if [ "$ftp_return_code" -ne 0 ]; then

                error_log " ${3} File transfer to ${6} failed"
                return 1
        else
                info_log " ${3} File transfer to ${6} successful"
                return 0

        fi

}

function measure_item() {

        : "
                $1=sourcefile
                $2=flag_include_header
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least two argument is required" && return 1

        local def_flag_include_header=0
        local _file_count

        flag_include_header=${2:-$def_flag_include_header}

        if ! test_path "${1}"; then

                error_log "${FUNCNAME[0]}: source function error"
                return 1

        fi >/dev/null

        if [ "$flag_include_header" -ne 0 ]; then

                _file_count=$(wc -l "${1}" | awk '{ print $1 }')

        else
                _file_count=$(awk ' NR>1' "${1}" | wc -l)
        fi

        measure_item_rc=$?

        if [ $measure_item_rc -ne 0 ] && [ -z "${_file_count}" ]; then

                error_log "${FUNCNAME[0]}: can not count lines in the files"
                return 1
        fi

        echo "${_file_count}"

}

######################################
# Linux file operations module: FILE OPERATION FUNCTIONS
#   copy_items_cloud
#   remove_directory_cloud
#######################################

function copy_items_cloud() {
        : "
                $1=sourcedatadirhdfs
                $2=destinationdirgcp
        "
        [ $# -ne 2 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if [ "$(echo "$2" | awk '{ print substr($0,1,2) }')" == 'gs' ]; then

                DISTCP_SETTINGS="-D HADOOP_OPTS=-Xmx12g -D HADOOP_CLIENT_OPTS='-Xmx12g -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled' -D 'mapreduce.map.memory.mb=12288' -D 'mapreduce.map.java.opts=-Xmx10g' -D 'mapreduce.reduce.memory.mb=12288' -D 'mapreduce.reduce.java.opts=-Xmx10g'"

                copy_to_gs_command="hadoop distcp ${DISTCP_SETTINGS} ${1} ${2}/"

                info_log "${FUNCNAME[0]}:command being executed is ${copy_to_gs_command}"

                eval "${copy_to_gs_command}" > /dev/null

                copy_items_cloud_rc=$?

                [ $copy_items_cloud_rc -ne 0 ] && fatal_log "${FUNCNAME[0]}:${copy_to_gs_command} failed to execute" && return 1

                info_log "${FUNCNAME[0]}:Data copied to GCP" && return 0

        else
                error_log "Destination directory:${2} doesn't look valid; NOT pointing to gcs bucket. Please check Input Dir and environment variables"

                return 1
        fi

}

function remove_directory_cloud() {
        : "
                $1=sourcedatadir
        "
        [ $# -ne 1 ] && error_log "${FUNCNAME[0]}: at least 1 argument is required" && return 1

        if ! test_directory_cloud "${1}"; then

                info_log "${FUNCNAME[0]}:directory does not exist in gcp not needed for removal ${1}" && return 0

        fi

        #[ $? -ne 0 ] && info_log "${FUNCNAME[0]}:directory does not exist in gcp not needed for removal ${1}" && return 0

        hadoop fs -rm -skipTrash -r "${1}/"

        remove_directory_cloud_rc=$?

        [ $remove_directory_cloud_rc -eq 0 ] && info_log "${FUNCNAME[0]}:removed all objects from gcp ${1}" && return 0

        [ $remove_directory_cloud_rc -ne 0 ] && error_log "${FUNCNAME[0]}:Unable to remove objects from gcp ${1}" && return 1

}

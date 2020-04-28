#!/bin/bash

######################################
# Linux file operations module:
#   move_item
#   get_content
#   test_path
#   expand_archive
#   compress_archive
#   copy_item
#   remove_item
#   rename_ftpitem
#   test_directory_contents
#######################################

function test_content() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if [ -s ${1} ]; then

                info_log "$FUNCNAME:${1} File has data present"

                return 0

        else
                error_log "$FUNCNAME:${1} File is empty"

                return 1
        fi

}

function test_path() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if [ -f ${1} ]; then

                info_log "$FUNCNAME:Files found in location ${1}"

                return 0

        else
                error_log "$FUNCNAME:Files not found for processing in location ${1}"

                return 1

        fi

}

function test_directory() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if ! test_cda_regex "${1}"; then
                return 1
        fi

        if $(hadoop fs -test -d ${1}); then

                info_log "$FUNCNAME:${1} directory exists"

                return 0

        else
                error_log "$FUNCNAME:${1} directory does not exist failing the process"

                return 1
        fi

}

function test_directory_contents() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if ! test_directory "${1}"; 
        then 
        return 1 
        fi 

        count=$(find ${1} -mindepth 1 -type f | wc -l)

        [ ${count} -eq 0 ] && error_log "$FUNCNAME: directory does not have any contents" && return 1

        [ ${count} -ne 0 ] && info_log "$FUNCNAME: directory has ${count} records" && return 0

}

function test_directory_cloud() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        cloud_dir=${1}

        if $(hadoop fs -test -d "${cloud_dir}"); then test_dir_return_code=0; else test_dir_return_code=1; fi

        [ $test_dir_return_code -ne 0 ] && info_log "$FUNCNAME: directory is not present in the cloud storagedir ${cloud_dir}" && return 1

        [ $test_dir_return_code -eq 0 ] && info_log "$FUNCNAME: directory is present in the cloud storagedir ${cloud_dir}" && return 0

}

function test_directory_contents_cloud() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if ! test_directory_cloud "${1}"; 
        then 
        return 1 
        fi

        count=$(hadoop fs -ls -R ${1} | grep -E '^-' | wc -l)

        [ ${count} -eq 0 ] && error_log "$FUNCNAME: directory does not have any contents" && return 1

        [ ${count} -ne 0 ] && info_log "$FUNCNAME: directory has ${count} records" && return 0

}

function test_cda_regex() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        local dir_name=${1}

        cda_folder=$(echo "${dir_name}" | grep -E -o "\/${CDA_FILE_REGEX}.*[^\']") || true

        [ -z "${cda_folder}" ] && [ "${cda_folder}" != " " ] && fatal_log "$FUNCNAME: ${dir_name} location is not a valid cda location" && return 1

        [ ! -z "${cda_folder}" ] && [ "${cda_folder}" != " " ] && info_log "$FUNCNAME: ${dir_name} location is a valid cda location" && return 0

}

function test_cda_regex_cloud() {
        : '
                $1=source
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        local dir_name=${1}

        cda_folder=$(echo "${dir_name}" | grep -E -o "\/${CDA_CLOUD_REGEX}.*[^\']") || true

        [ -z "${cda_folder}" ] && [ "${cda_folder}" != " " ] && fatal_log "$FUNCNAME: ${dir_name} location is not a valid cda location" && return 1

        [ !-z "${cda_folder}" ] && [ "${cda_folder}" != " " ] && info_log "$FUNCNAME: ${dir_name} location is a valid cda location" && return 0
}

function move_item() {
        : '
                $1=sourcefile
                $2=destinationdir
        '
        [ $# -ne 2 ] && error_log "$FUNCNAME: at least two argument is required" && return 1

        if ! test_path ${1} then return 1 fi

        if ! test_directory ${2} then return 1 fi

        mv -v ${1} ${2}

        if [ $? -ne 0 ]; then

                error_log "$FUNCNAME:Unable to move objects from ${1} to ${2}"

                return 1
        else

                info_log "$FUNCNAME:Successfully moved objects from ${1} to ${2}"

                return 0

        fi

}

function expand_archive() {

        : '
                $1=source
                $2=destination
        '
        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 2 argument is required" && return 1

        if ! test_path ${1} then return 1 fi

        if ! test_content ${1} then return 1 fi

        if ! test_directory ${2} then return 1 fi

        tar -xvf ${1} -C ${2}

        if [ $? -ne 0 ]; then

                error_log "$FUNCNAME:Error. Not able to unzip the file ${1}."

                return 1

        else
                info_log "$FUNCNAME:Success. Unzipped  ${1} into the location."

                return 0
        fi

}

function compress_archive() {
        : '
                $1=sourcedatadir
                $2=destinationdir
                $3=compressedfilename
        '
        [ $# -ne 3 ] && error_log "$FUNCNAME: at least 3 argument is required" && return 1

        $(cd "${2}" && zip -rq -j "${3}" "${1}")

        if [ $? -ne 0 ]; then

                error_log "$FUNCNAME:Unable to create the zip file ${3} from the data location ${1}"

                return 1

        else
                info_log "$FUNCNAME:Successfully created the files compressed file ${3}"

                return 0
        fi

}

function copy_item() {
        : '
                $1=sourcefile
                $2=destinationdir
        '
        [ $# -ne 2 ] && error_log "$FUNCNAME: at least two argument is required" && return 1

       if ! test_path ${1} then return 1 fi

       if ! test_directory ${2} then return 1 fi

        hadoop fs -cp ${1} ${2}

        if [ $? -ne 0 ]; then

                error_log "$FUNCNAME:Unable to copy objects from ${1} to ${2}"

                return 1
        else

                info_log "$FUNCNAME:Successfully copied objects from ${1} to ${2}"

                return 0

        fi

}

function remove_items() {

        : '
                $1=sourcedatadir
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        directory=${1}

       if ! test_directory ${1} then return 1 fi

        info_log "$FUNCNAME:${directory} is being evaluated for removal"

        files=($(hadoop fs -ls ${directory} | awk '!/^d/ {print $8}'))

        [ ${#files[@]} -eq 0 ] && error_log "$FUNCNAME: ${directory} did not generate any records" && return 1

        info_log "$FUNCNAME:${files} list evaluated for removal"

        for file in ${files[@]}; do

                if [ -f "${file}" ]; then

                        rm -v ${file}

                else

                        error_log "$FUNCNAME:file ${file} not found"

                        return 1

                fi

        done

        return 0

}

function move_items() {

        : '
                $1=sourcedatadir
                $2=destinationdir
        '
        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        source_directory=${1}

       if ! destination_directory=${2} then return 1 fi

       if ! test_directory ${source_directory} then return 1 fi

       if ! test_directory ${destination_directory} then return 1 fi

        files=($(hadoop fs -ls ${source_directory} | awk '!/^d/ {print $8}'))

        [ ${#files[@]} -eq 0 ] && error_log "$FUNCNAME: ${source_directory} did not generate any records" && return 1

        for file in ${files[@]}; do

                info_log "$FUNCNAME: ${file} file being evaluated for size restrictions prior to movement to dir"

                if [ -s "${file}" ]; then

                        move_item ${file} ${destination_directory}

                        [ $? -ne 0 ] && return 1

                else

                        error_log "$FUNCNAME:${file} files have empty content"

                        return 1

                fi

        done

        return 0

}

function rename_ftpitem() {

        : '
                $1=sourcedatadir
                $2=destinationdir
                $3=sourcefilename
                $4=renamedfilename
                $5=ftppassword
                $6=ftpservername

        '
        #objLocationTrgt=${FILE_ROOT_DIR}/"$modelname"/compressfilestozip/
        #zipFileName="$modelname"_Scores_Details_"$wkdt"T.zip
        #zipFileNameN="$modelname"_Scores_Details_"$wkdt"N.zip

        sshpass -p ${5} sftp ${6} <<!
                cd ${2} 
                put ${1}
                rename ${3} ${4}
!
        #Send success email otherwise exit
        if [ $? -ne 0 ]; then

                error_log " ${3} File transfer to ${6} failed"
                exit 1
        else
                info_log " ${3} File transfer to ${6} successful"

        fi

}

function copy_items_cloud() {
        : '
                $1=sourcedatadirhdfs
                $2=destinationdirgcp
        '
        [ $# -ne 2 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        if [ "$(echo $2 | awk '{ print substr($0,1,2) }')" == 'gs' ]; then

                DISTCP_SETTINGS="-D HADOOP_OPTS=-Xmx12g -D HADOOP_CLIENT_OPTS='-Xmx12g -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+CMSParallelRemarkEnabled' -D 'mapreduce.map.memory.mb=12288' -D 'mapreduce.map.java.opts=-Xmx10g' -D 'mapreduce.reduce.memory.mb=12288' -D 'mapreduce.reduce.java.opts=-Xmx10g'"

                copy_to_gs_command="hadoop distcp ${DISTCP_SETTINGS} ${1} ${2}/"

                info_log "$FUNCNAME:command being executed is ${copy_to_gs_command}"

                eval ${copy_to_gs_command} >/dev/null

                [ $? -ne 0 ] && fatal_log "$FUNCNAME:${copy_to_gs_command} failed to execute" && return 1

                info_log "$FUNCNAME:Data copied to GCP" && return 0

        else
                error_log "Destination directory:${2} doesn't look valid; NOT pointing to gcs bucket. Please check Input Dir and environment variables"

                return 1
        fi

}

function remove_directory_cloud() {
        : '
                $1=sourcedatadir
        '
        [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 argument is required" && return 1

        #test_directory_cloud ${1}

        #[ $? -ne 0 ] && info_log "$FUNCNAME:directory does not exist in gcp not needed for removal ${1}" && return 0

        if $(hadoop fs -test -d "${1}"); then

                hadoop fs -rm -skipTrash -r "${1}/"

                remove_directory_cloud_ret_code=$?

                [ $remove_directory_cloud_ret_code -eq 0 ] && info_log "$FUNCNAME:removed all objects from gcp ${1}" && return 0

                [ $remove_directory_cloud_ret_code -ne 0 ] && error_log "$FUNCNAME:Unable to remove objects from gcp ${1}" && return 1

        else

                info_log "$FUNCNAME:directory does not exist in gcp not needed for removal ${1}" && return 0

        fi

}

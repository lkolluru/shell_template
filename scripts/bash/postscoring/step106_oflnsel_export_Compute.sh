#!/bin/bash

#Set Global Variables
set -uo pipefail
set -E
set -o errtrace
source ${STEP_SHELL_TEMPLATE_SCRIPT}
source ${FILE_HANDLER_SCRIPT}
trap clean_up SIGINT SIGHUP SIGTERM EXIT
trap 'gen_step_error ${LINENO} ${?}' ERR

#Functions

function gen_jar_execution() {

    [ $# -ne 6 ] && error_log "$FUNCNAME: at least 6 arguments are required" && return 1

    CALCENGINE_JAR_VER_NAME=$1
    LIBJARS=$2
    JAR_ENV=$3
    JAR_FG=$4
    JAR_RESOURCES=$5
    PWD_FILE_RES=$6
    info_log "$FUNCNAME:code execution directory ${JAR_DIRECTORY}"
    info_log "$FUNCNAME:jar execution version ${CALCENGINE_JAR_VER_NAME}"
    info_log "$FUNCNAME:jar resources info ${JAR_RESOURCES}"
    info_log "$FUNCNAME:password file resources info ${PWD_FILE_RES}"

    hadoop jar ${CALCENGINE_JAR_VER_NAME} com.pch.hdlCalcEngine.StandaloneCalcEngine -libjars ${LIBJARS} ${JAR_ENV} ${JAR_FG} ${JAR_RESOURCES} ${PWD_FILE_RES}
    return_code=$?

    [ $return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) failed to execute successfully" && return 1

    [ $return_code -eq 0 ] && info_log "$FUNCNAME: jar execution compelted successfully for ${JAR_FG}" && return 0
}

function post_process_validations() {

    [ $# -ne 1 ] && error_log "$FUNCNAME: at least 1 arguments are required" && return 1

    { ## Load data from sql server into the logging dir post the run_archive logs from the consolidated operational view
        validation_fg="${1}" &&
            validation_table_query="select  variablefunctionalgroupcode, validatoins_instance_failures, other_instance_failures 
                                   from appinfo.vw_get_genjar_validation_step_failure_info 
                                   where variablefunctionalgroupcode = '${validation_fg}' AND \$CONDITIONS;" &&
            validation_dir_name="${validation_fg}_scoring_validations" &&
            validation_dir_path="${PROJ_STGDATA_FILES_DIR}"/"${validation_dir_name}" &&
            validation_options_file="${SQOOP_IMPORT_OPTIONS_FILE}" &&
            scoopimportquery "${validation_table_query}" "${validation_dir_path}" "${validation_options_file}"

    }
    sql_import_return_code=$?
    [ $sql_import_return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) failed to execute successfully" && return 1

    { ## parse the file and convert the csv files into array of 3 values for processing
        readarray -t validation_file_parser <"${validation_dir_path}/part-m-00000"

        [ "${#validation_file_parser[@]}" -ne 1 ] && error_log "$FUNCNAME:control file needs to have only a single record" && return 1

        IFS=',' read -ra validation_file_value_array <<<"$(echo "${validation_file_parser[0]}")"

        functional_group=${validation_file_value_array[0]}

        validation_fail_count=${validation_file_value_array[1]}

        compute_fail_count=${validation_file_value_array[2]}

        info_log "$FUNCNAME:record counts from the db are Validation:$validation_fail_count and Compute:$compute_fail_count"

    }
    sql_control_file_return_code=$?
    [ $sql_control_file_return_code -ne 0 ] && error_log "$FUNCNAME: $(basename ${0}) failed to execute successfully" && return 1

    if [ $validation_fail_count -ne 0 ] && [ $compute_fail_count -eq 0 ]; then

        info_log "$FUNCNAME: $(basename ${0}) failed on query validations"
        return 2
    fi

    info_log "$FUNCNAME: the process validations successfully completed" && return 0
}

function main() {

    info_log "$FUNCNAME:Command executed: ${0}"

    cd ${JAR_DIRECTORY}

    if ! gen_jar_execution ${CALCENGINE_JAR_VER_NAME} ${LIBJARS} ${JAR_ENV} ${EXPORT_JAR_FG} ${JAR_RESOURCES} ${PWD_FILE_RES}; then

        post_process_validations ${EXPORT_JAR_FG}

        val_ret_code=$?

        if [ $val_ret_code -eq 1 ]; then

            exit 1

        elif [ $val_ret_code -eq 2 ]; then

            exit 200

        else
            return 0

        fi

    fi

}

#Setup new or edit log file.
prepare_log_file

main 2>&1 | tee -a ${step_log_file}

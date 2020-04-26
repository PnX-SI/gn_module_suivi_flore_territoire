#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import visits script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./import_visits.sh [options]
Update settings.ini, section "Import visits" before run this script.
     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported visits
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "$@"; do
        shift
        case "$arg" in
            "--help") set -- "$@" "-h" ;;
            "--verbose") set -- "$@" "-v" ;;
            "--debug") set -- "$@" "-x" ;;
            "--config") set -- "$@" "-c" ;;
            "--delete") set -- "$@" "-d" ;;
            "--"*) exitScript "ERROR : parameter '$arg' invalid ! Use -h option to know more." 1 ;;
            *) set -- "$@" "$arg"
        esac
    done

    while getopts "hvxdc:" option; do
        case "$option" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="$OPTARG" ;;
            "d") action="delete" ;;
            "?") exitScript "ERROR : parameter '$OPTARG' invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Define global constants and variables
    action="import"

    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${visits_import_log}"

    checkSuperuser
    commands=("psql" "csvtool")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Visits import script started at: ${fmt_time_start}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    createTmpTables
    #importCsvData
    importCsvDataByCopy

    if [[ "$action" = "import" ]]; then
        importVisits
    elif [[ "$action" = "delete" ]]; then
        deleteVisits
    fi

    if [[ -n ${verbose-} ]]; then
        displayPersons
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function createTmpTables() {
    printMsg "Create temporary tables"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -v visitsHasObserversTmpTable="${visits_table_tmp_has_observers}" \
            -v visitsObserversTmpTable="${visits_table_tmp_observers}" \
            -v datasetId="${dataset_id}" \
            -f "${data_dir}/import_visits_tmp_tables.sql"
}

function importCsvData() {
    visit_id=0
    declare -g -A persons
    printMsg "Import visits data into tmp tables"
    local head="$(csvtool head 1 "${visits_csv_path}")"
    local readonly tasks_count="$(($(csvtool height "${visits_csv_path}") - 1))"
    local tasks_done=0
    # Don't use pipe that run "while" in sub shell, use substitution (see below "done") to access to persons variable
    while IFS= read -r line; do
        local site_code="$(printf "$head\n$line" | csvtool namedcol ${visits_column_id} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local meshe_code="$(printf "$head\n$line" | csvtool namedcol ${visits_column_meshe} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local observers="$(printf "$head\n$line" | csvtool namedcol ${visits_column_observer} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local organisms="$(printf "$head\n$line" | csvtool namedcol ${visits_column_organism} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local date_start="$(printf "$head\n$line" | csvtool namedcol ${visits_column_date_start} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local date_end="$(printf "$head\n$line" | csvtool namedcol ${visits_column_date_end} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local status="$(printf "$head\n$line" | csvtool namedcol ${visits_column_status} - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

        # Clean and format data
        (( visit_id+=1 ))
        site_code=$(trim "${site_code}")
        meshe_code=$(trim "${meshe_code}")
        date_start=$(trim "${date_start//\//-}")
        date_end=$(trim "${date_end//\//-}")
        status=$(trim "${status}")
        #echo "|${site_code}|${meshe_code}|${date_start}|${date_end}|${status}|"

        # Associate observers and organisms
        local observers_concat=$(trim "${observers// /_}")
        local observers_list=(${observers_concat//|/ })
        local organisms_concat=$(trim "${organisms// /_}")
        local organisms_list=(${organisms_concat//|/ })

        printVerbose "Insert temporary visit: ${visit_id}"
        export PGPASSWORD="${user_pg_pass}"; \
            psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
                -v moduleSchema="${module_schema}" \
                -v visitsTmpTable="${visits_table_tmp_visits}" \
                -v visitId="${visit_id}" \
                -v siteCode="${site_code}" \
                -v dateStart="${date_start}" \
                -v dateEnd="${date_end}" \
                -v mesheCode="${meshe_code}" \
                -v presence="${status}" \
                -f "${data_dir}/import_visits_tmp.sql"

        for i in "${!observers_list[@]}"; do
            # Create hash of full observer name as index
            local idx=$(printf "%s" "${observers_list[i]}" | tr '[:upper:]' '[:lower:]' | md5sum | cut -d " " -f 1)
            local firstname="${observers_list[i]#*_}"
            local lastname="${observers_list[i]%_*}"
            local organism="${organisms_list[i]}"

            printVerbose "\tInsert temporary observers and links to visit: ${firstname} ${lastname}"
            export PGPASSWORD="${user_pg_pass}"; \
                psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
                    -v moduleSchema="${module_schema}" \
                    -v visitsOberserversTmpTable="${visits_table_tmp_observers}" \
                    -v visitsHasOberserversTmpTable="${visits_table_tmp_has_observers}" \
                    -v md5Sum="${idx}" \
                    -v firstname="${firstname}" \
                    -v lastname="${lastname}" \
                    -v organism="${organism}" \
                    -v visitId="${visit_id}" \
                    -f "${data_dir}/import_visits_tmp_observers.sql"

            if ! [[ ${persons["${idx}"]+muahaha} ]]; then
                declare -A person
                person["firstname"]="${observers_list[i]#*_}"
                person["lastname"]="${observers_list[i]%_*}"
                person["organism"]="${organisms_list[i]}"
                local string=$(declare -p person)
                persons["${idx}"]=${string}
            fi
        done

        (( tasks_done+=1 ))
        if ! [[ -n ${verbose-} ]]; then
            displayProgressBar $tasks_count $tasks_done "importing tmp data"
        fi

    done < <(stdbuf -oL csvtool drop 1 "${visits_csv_path}")
    echo
}

function importCsvDataByCopy() {
    printMsg "Import visits data into tmp tables"
    export PGPASSWORD="$db_superuser_pass"; \
        psql -h "${db_host}" -U "${db_superuser_name}" -d "${db_name}" ${psql_verbosity} \
        -v moduleSchema="${module_schema}" \
        -v visitsTmpTable="${visits_table_tmp_visits}" \
        -v visitsObserversTmpTable="${visits_table_tmp_observers}" \
        -v visitsHasObserversTmpTable="${visits_table_tmp_has_observers}" \
        -v visitsCsvPath="${visits_csv_path}" \
        -f "${data_dir}/import_visits_copy.sql"
}

function importVisits() {
    printMsg "Insert visits from temporary data"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -v visitsHasObserversTmpTable="${visits_table_tmp_has_observers}" \
            -v visitsObserversTmpTable="${visits_table_tmp_observers}" \
            -v moduleCode="${module_code}" \
            -v meshesCode="${meshes_code}" \
            -v observersListId="${observers_list_id}" \
            -f "${data_dir}/import_visits.sql"
}

function displayPersons() {
    echo "Persons data processed:"
    for key in "${!persons[@]}"; do
        printf "$key\n"
        printf "\t${persons["$key"]}\n"
        eval "${persons["$key"]}"
        for key in "${!person[@]}"; do
            printf "\t$key - ${person["$key"]}\n"
        done
    done
}

function deleteVisits() {
    printMsg "Delete visits listed in CSV file"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -v visitsHasObserversTmpTable="${visits_table_tmp_has_observers}" \
            -v visitsObserversTmpTable="${visits_table_tmp_observers}" \
            -v moduleCode="${module_code}" \
            -v meshesCode="${meshes_code}" \
            -v observersListId="${observers_list_id}" \
            -f "${data_dir}/delete_visits.sql"
}

main "${@}"

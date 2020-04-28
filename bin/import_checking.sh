#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import checking.g
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./import_checking.sh [options]
     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
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
            "?") exitScript "ERROR : parameter '$OPTARG' invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${visits_import_log}"

    commands=("psql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "SFT import checking started at: ${fmt_time_start}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    checkImports

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function checkImports() {
    printMsg "Display infos about SFT imports"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v datasetId="${dataset_id}" \
            -v moduleCode="${module_code}" \
            -v meshesCode="${meshes_code}" \
            -v observersListId="${observers_list_id}" \
            -f "${data_dir}/import_checking.sql"
}

main "${@}"

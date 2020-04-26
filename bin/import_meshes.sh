#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import meshes script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./import_meshes.sh [options]
Update settings.ini, section "Import meshes" before run this script.

     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported meshes
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--delete") set -- "${@}" "-d" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxdc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "d") action="delete" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
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
    redirectOutput "${meshes_import_log}"

    checkSuperuser
    commands=("psql" "shp2pgsql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    printInfo "Meshes import script started at: ${fmt_time_start}"
    loadShapeToPostgresql
    if [[ "${action}" = "import" ]]; then
        importMeshes
    elif [[ "${action}" = "delete" ]]; then
        deleteMeshes
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function importMeshes() {
    printMsg "Insert meshes into « ref_geo.l_areas »"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v sridLocal="${srid_local}" \
            -v meshGeomColumn="${meshes_geom_column}" \
            -v meshNameColumn="${meshes_name_column}" \
            -v meshesSource="${meshes_source}" \
            -v meshesCode="${meshes_code}" \
            -v moduleSchema="${module_schema}" \
            -v meshesTmpTable="${meshes_tmp_table}" \
            -f "${data_dir}/import_meshes.sql"
}

function deleteMeshes() {
    printMsg "Delete meshes listed in '${meshes_shape_path##*/}' SHP file from « ref_geo.l_areas » and linked tables"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleSchema="${module_schema}" \
            -v meshesTmpTable="${meshes_tmp_table}" \
            -v meshesCode="${meshes_code}" \
            -v meshNameColumn="${meshes_name_column}" \
            -f "${data_dir}/delete_meshes.sql"
}

function loadShapeToPostgresql() {
    printMsg "Export meshes SHP to PostGis and create meshes temporary table"
    export PGPASSWORD="${user_pg_pass}"; \
        shp2pgsql -c -s ${srid_local} "${meshes_shape_path}" "${module_schema}.${meshes_tmp_table}" \
        | psql -h "${db_host}" -U "${user_pg}" -d "${db_name}"
}

main "${@}"

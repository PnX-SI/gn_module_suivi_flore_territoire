#!/usr/bin/env bash
# Encoding : UTF-8
# SFT module install Database script.
#
# Documentation : https://github.com/PnX-SI/gn_module_suivi_flore_territoire
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
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
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
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
    redirectOutput "${install_log}"

    checkSuperuser
    commands=("psql" "shp2pgsql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Install module DB script started at: ${fmt_time_start}"

    #+----------------------------------------------------------------------------------------------------------+
    printMsg "Create module schema into GeoNature database"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleSchema="${module_schema}" \
            -v meshesCode="${meshes_code}" \
            -f "${data_dir}/sft_schema.sql"

    #+----------------------------------------------------------------------------------------------------------+
    printMsg "Create module lists (no values => use import) : meshes, taxons, perturbation"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleCode="${module_code}" \
            -v meshesCode="${meshes_code}" \
            -v meshesName="${meshes_name}" \
            -v meshesDesc="${meshes_desc}" \
            -v taxonListName="${taxon_list_name}" \
            -v perturbationCode="${perturbation_code}" \
            -v perturbationSrc="${perturbation_src}" \
            -v siteTypeCode="${site_type_code}" \
            -v siteTypeSrc="${site_type_src}" \
            -f "${data_dir}/sft_data_ref.sql"

    #+----------------------------------------------------------------------------------------------------------+
    # Include sample data into database
    if [ "${insert_sample_data}" = true ]; then
        printMsg "Insert module data sample"

        printMsg "Insert module sample metadata (acquisition framework and dataset)"
        export PGPASSWORD="${user_pg_pass}"; \
            psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
                -v moduleCode="${module_code}" \
                -f "${data_dir}/sft_sample_metadata.sql"

        printMsg "Import meshes data sample"
        bash "${script_dir}/import_meshes.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import sites data sample"
        bash "${script_dir}/import_sites.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import taxons data sample"
        bash "${script_dir}/import_taxons.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import nomenclatures data sample"
        bash "${script_dir}/import_nomenclatures.sh" -c "${conf_dir}/install_data_sample.ini" -v
    else
        printPretty "--> Module data sample was NOT included in database" ${Gra-}
    fi

    #+----------------------------------------------------------------------------------------------------------+
    displayTimeElapsed
}

main "${@}"

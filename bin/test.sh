#!/usr/bin/env bash
# Encoding : UTF-8
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() { 
    cat << EOF
Usage: ./import_meshes.sh [options]
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
            "c") setting_file_path=${OPTARG} ;;
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
    
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/utils.bash"

    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${log_dir}/$(date +'%F')_test.log"    

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Test script started at: ${fmt_time_start}"
    
    checkSuperuser
    checkBinary "sudo"
    commands=("psql" "shp2pgsql" "csvtool")
    checkBinary "${commands[@]}"

    printPretty "Test printPretty green" ${Gre}
    printMsg "Test section"
    printError "Test erreur"
    printInfo "Test infos"
    printVerbose "Test texte verbeux"

    head="$(csvtool head 1 "$import_dir/taxons.csv")"
    stdbuf -oL csvtool drop 1 "$import_dir/taxons.csv"  |
        while IFS= read -r line; do
            col="$(printf "$head\n$line" | csvtool namedcol name - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
            echo "'$col'"
        done

    count=100
    done=0
    while [ $done -le $count ]; do
        (( done += 1 ))
        displayProgressBar $count $done
        sleep 0.01
    done
    echo
    
    #+----------------------------------------------------------------------------------------------------------+
    displayTimeElapsed
}

main "${@}"

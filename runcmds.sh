#!/bin/bash
#
# Sequentially execute a list of commands by checking exit status.
#
# In case of failure, then display the failing command number
# and let user to start command list execution from a specific index.
#
# For more information, use the -h | --help option
#
# @author Aurelien Bourdon

#################################################
# User tunable variables                        #
#################################################

# List of command to execute
commands=()

# List of environment variables to use
environment=()

# Index to start from
functionalIndexToStart=1

# Source file
commandsFile=''

#################################################
# Internal variables                            #
#################################################

# Application name
APP=`basename $0`

# Log levels
INFO='INFO'
ERROR='ERROR'

#################################################
# Internal functions                            #
#################################################

# Print a log to console
#
# @param $1 log level
# @param $2 message content
# @return nothing
function log {
    level="$1"
    message="$2"
    echo "$APP [$level] $message"
}

# Display help message and exit
#
# @param nothing
# @return nothing
function help {
    log INFO "${APP}: Execute a list of commands"
    log INFO "usage: ${APP} [OPTIONS] [COMMAND_1 COMMAND_2 ...]"
    log INFO 'OPTIONS:'
    log INFO '      -f | --from INDEX                       From which command number (INDEX) to start. Start from 1.'
    log INFO '      -h | --help                             Display this helper message.'
    log INFO '      -s | --source PATH                      The file PATH that list commands to execute.'
    log INFO '                                              File format: one line by command. Empty line or line starting by the "#" character will be ignored.'
    log INFO '      -e | --environment ENV_KEY ENV_VALUE    Set the environment key variable ENV_KEY to the value ENV_VALUE.'
    log INFO '                                              Once defined, environment variable can be used from command to execute as the following: ${ENV_KEY}.'
    log INFO '                                              For instance, the command "echo ${foo}" will be interpreted as "echo bar" by using the option "-e foo bar", or "--environment foo bar".'
    log INFO 'COMMAND_1 COMMAND_2 ...:'
    log INFO '      Command list to execute in order. If exists, then the -s | --source option is disabled.'
    exit 1
}

# Parse user-given options
#
# @param $@ user options
# @return nothing
function parseOptions {
    while [[ $# -gt 0 ]]; do
        argument="$1"
        case $argument in
            -h|--help)
                help;
                ;;
            -f|--from)
                value="$2"
                if [[ $value -le 0 ]]; then
                    log ERROR 'Bad start index value. Value has to be greater or equal to 1.'
                    exit
                fi
                functionalIndexToStart=$value
                shift
                ;;
            -s|--source)
                value="$2"
                if [ ! -r $value ]; then
                    log ERROR "Unable to parse commands file '$value'. Exiting."
                    exit
                fi
                commandsFile=$value
                shift
                ;;
            -e|--environment)
                environment+=("$2")
                environment+=("$3")
                shift
                shift
                ;;
            *)
                commands+=("$argument")
                ;;
        esac
        shift
    done
}

# Fill the $commands array from commands fetched from the associated file
#
# @param nothing
# @return nothing
function parseCommandsFile {
    while IFS='' read -r command || [[ -n "$command" ]]; do
        if [[ "$command" != "" &&  "$command" != \#* ]]; then
            commands+=("$command")
        fi
    done < $commandsFile
}

# Execute command list
#
# @param nothing
# @return noting
function runCommands {
    indexToStart=`expr $functionalIndexToStart - 1`
    commandsLength=${#commands[@]}

    if [ $commandsLength -eq 0 ]; then
        log INFO 'Nothing to execute.'
        exit
    elif [ $indexToStart -ge $commandsLength ]; then
        log ERROR "Index to start > commands length"
        exit
    fi

    log INFO 'Starting command execution flow...'
    indexToEnd=`expr $commandsLength - 1`
    for index in `seq $indexToStart $indexToEnd`; do
        functionalIndex=`expr $index + 1`
        command="${commands[$index]}"

        # Parse environment variables
        environmentLength=${#environment[@]}
        if [ ! $environmentLength -eq 0 ]; then
            for environmentIndex in `seq 0 2 $(expr ${environmentLength} - 1)`; do
                environmentKey=${environment[$environmentIndex]}
                environmentValue=${environment[$environmentIndex+1]}
                command=`echo "$command" | sed "s/\\${${environmentKey}}/${environmentValue}/g"`
            done;
        fi

        # Execute command
        log INFO "----- #${functionalIndex}: $command"
        eval "$command"

        # Check exit status
        if [ $? -ne 0 ]; then
            log ERROR "Command #${functionalIndex} failed"
            log ERROR "Please fix it and rerun by executing: ${APP} --from ${functionalIndex}"
            exit 1
        fi
    done
    log INFO 'Command execution flow done.'
}

# Main entry point
#
# @param $@ the program arguments
# @return nothing
function main {
    parseOptions "$@"
    if [[ ${#commands[@]} -eq 0 && $commandsFile != '' ]]; then
        parseCommandsFile
    fi
    runCommands
}

#################################################
# Execution                                     #
#################################################

main "$@"

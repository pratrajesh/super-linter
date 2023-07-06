#!/usr/bin/env bash

################################################################################
################################################################################
########### Super-Linter (Lint all the code) @admiralawkbar ####################
################################################################################
################################################################################

##################################################################
# Debug Vars                                                     #
# Define these early, so we can use debug logging ASAP if needed #
##################################################################
# RUN_LOCAL="${RUN_LOCAL}"                            # Boolean to see if we are running locally
ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-false}" # Boolean to see even more info (debug)
IMAGE="${IMAGE:-standard}"                            # Version of the Super-linter (standard,slim,etc)

##################################################################
# Log Vars                                                       #
# Define these early, so we can use debug logging ASAP if needed #
##################################################################
LOG_FILE="${LOG_FILE:-super-linter.log}" # Default log file name (located in GITHUB_WORKSPACE folder)
LOG_LEVEL="${LOG_LEVEL:-VERBOSE}"        # Default log level (VERBOSE, DEBUG, TRACE)
CREATE_LOG_FILE="${CREATE_LOG_FILE:-"false"}"
export CREATE_LOG_FILE

if [[ ${ACTIONS_RUNNER_DEBUG} == true ]]; then LOG_LEVEL="DEBUG"; fi
# Boolean to see trace logs
LOG_TRACE=$(if [[ ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_TRACE
# Boolean to see debug logs
LOG_DEBUG=$(if [[ ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_DEBUG
# Boolean to see verbose logs (info function)
LOG_VERBOSE=$(if [[ ${LOG_LEVEL} == "VERBOSE" || ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_VERBOSE
# Boolean to see notice logs
LOG_NOTICE=$(if [[ ${LOG_LEVEL} == "NOTICE" || ${LOG_LEVEL} == "VERBOSE" || ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_NOTICE
# Boolean to see warn logs
LOG_WARN=$(if [[ ${LOG_LEVEL} == "WARN" || ${LOG_LEVEL} == "NOTICE" || ${LOG_LEVEL} == "VERBOSE" || ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_WARN
# Boolean to see error logs
LOG_ERROR=$(if [[ ${LOG_LEVEL} == "ERROR" || ${LOG_LEVEL} == "WARN" || ${LOG_LEVEL} == "NOTICE" || ${LOG_LEVEL} == "VERBOSE" || ${LOG_LEVEL} == "DEBUG" || ${LOG_LEVEL} == "TRACE" ]]; then echo "true"; fi)
export LOG_ERROR

#########################
# Source Function Files #
#########################
# shellcheck source=/dev/null
source /action/lib/functions/buildFileList.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/detectFiles.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/linterRules.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/linterVersions.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/log.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/updateSSL.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/validation.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/worker.sh # Source the function script(s)
# shellcheck source=/dev/null
source /action/lib/functions/setupSSH.sh # Source the function script(s)

###########
# GLOBALS #
###########
# GitHub API root url
if [ -n "$GITHUB_CUSTOM_API_URL" ]; then
  GITHUB_API_URL="${GITHUB_CUSTOM_API_URL}"
elif [ -z "$GITHUB_API_URL" ]; then
  GITHUB_API_URL="https://api.github.com"
fi
# Remove trailing slash if present
GITHUB_API_URL="${GITHUB_API_URL%/}"

# Default Vars
DEFAULT_RULES_LOCATION='/action/lib/.automation'          # Default rules files location
LINTER_RULES_PATH="${LINTER_RULES_PATH:-.github/linters}" # Linter rules directory
VERSION_FILE='/action/lib/functions/linterVersions.txt'   # File to store linter versions
export VERSION_FILE                                       # Workaround SC2034

###############
# Rules files #
###############
GITHUB_ACTIONS_COMMAND_ARGS="${GITHUB_ACTIONS_COMMAND_ARGS:-null}"
OPENAPI_FILE_NAME=".openapirc.yml"
SUPPRESS_FILE_TYPE_WARN="${SUPPRESS_FILE_TYPE_WARN:-false}"
SUPPRESS_POSSUM="${SUPPRESS_POSSUM:-false}"
SSH_SETUP_GITHUB="${SSH_SETUP_GITHUB:-false}"
SSH_INSECURE_NO_VERIFY_GITHUB_KEY="${SSH_INSECURE_NO_VERIFY_GITHUB_KEY:-false}"
YAML_ERROR_ON_WARNING="${YAML_ERROR_ON_WARNING:-false}"

##################
# Language array #
##################
LANGUAGE_ARRAY=('OPENAPI')

##############################
# Linter command names array #
##############################
declare -A LINTER_NAMES_ARRAY
LINTER_NAMES_ARRAY['OPENAPI']="spectral"

############################################
# Array for all languages that were linted #
############################################
LINTED_LANGUAGES_ARRAY=() # Will be filled at run time with all languages that were linted

###################
# GitHub ENV Vars #
###################
# ANSIBLE_DIRECTORY="${ANSIBLE_DIRECTORY}"         # Ansible Directory
MULTI_STATUS="${MULTI_STATUS:-true}"       # Multiple status are created for each check ran
DEFAULT_BRANCH="${DEFAULT_BRANCH:-master}" # Default Git Branch to use (master by default)
# DISABLE_ERRORS="${DISABLE_ERRORS}"               # Boolean to enable warning-only output without throwing errors
# FILTER_REGEX_INCLUDE="${FILTER_REGEX_INCLUDE}"   # RegExp defining which files will be processed by linters (all by default)
# FILTER_REGEX_EXCLUDE="${FILTER_REGEX_EXCLUDE}"   # RegExp defining which files will be excluded from linting (none by default)
# GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH}"         # Github Event Path
# GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"         # GitHub Org/Repo passed from system
# GITHUB_RUN_ID="${GITHUB_RUN_ID}"                 # GitHub RUn ID to point to logs
# GITHUB_SHA="${GITHUB_SHA}"                       # GitHub sha from the commit
# GITHUB_WORKSPACE="${GITHUB_WORKSPACE}"           # Github Workspace
# TEST_CASE_RUN="${TEST_CASE_RUN}"                 # Boolean to validate only test cases
# VALIDATE_ALL_CODEBASE="${VALIDATE_ALL_CODEBASE}" # Boolean to validate all files

IGNORE_GITIGNORED_FILES="${IGNORE_GITIGNORED_FILES:-false}"

# Do not ignore generated files by default for backwards compatibility
IGNORE_GENERATED_FILES="${IGNORE_GENERATED_FILES:-false}"

################
# Default Vars #
################
DEFAULT_VALIDATE_ALL_CODEBASE='true'                # Default value for validate all files
DEFAULT_WORKSPACE="${DEFAULT_WORKSPACE:-/tmp/lint}" # Default workspace if running locally
DEFAULT_RUN_LOCAL='false'                           # Default value for debugging locally
DEFAULT_TEST_CASE_RUN='false'                       # Flag to tell code to run only test cases

###############################################################
# Default Vars that are called in Subs and need to be ignored #
###############################################################
DEFAULT_DISABLE_ERRORS='false'                                  # Default to enabling errors
export DEFAULT_DISABLE_ERRORS                                   # Workaround SC2034
ERROR_ON_MISSING_EXEC_BIT="${ERROR_ON_MISSING_EXEC_BIT:-false}" # Default to report a warning if a shell script doesn't have the executable bit set to 1
export ERROR_ON_MISSING_EXEC_BIT
RAW_FILE_ARRAY=()                   # Array of all files that were changed
export RAW_FILE_ARRAY               # Workaround SC2034
TEST_CASE_FOLDER='.automation/test' # Folder for test cases we should always ignore
export TEST_CASE_FOLDER             # Workaround SC2034

##########################
# Array of changed files #
##########################
for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
  FILE_ARRAY_VARIABLE_NAME="FILE_ARRAY_${LANGUAGE}"
  debug "Setting ${FILE_ARRAY_VARIABLE_NAME} variable..."
  eval "${FILE_ARRAY_VARIABLE_NAME}=()"
done

################################################################################
########################## FUNCTIONS BELOW #####################################
################################################################################
################################################################################
#### Function Header ###########################################################
Header() {
  ###############################
  # Give them the possum action #
  ###############################
  if [[ "${SUPPRESS_POSSUM}" == "false" ]]; then
    /bin/bash /action/lib/functions/possum.sh
  fi

  ##########
  # Prints #
  ##########
  info "---------------------------------------------"
  info "--- GitHub Actions Multi Language Linter ----"
  info " - Image Creation Date:[${BUILD_DATE}]"
  info " - Image Revision:[${BUILD_REVISION}]"
  info " - Image Version:[${BUILD_VERSION}]"
  info "---------------------------------------------"
  info "---------------------------------------------"
  info "The Super-Linter source code can be found at:"
  info " - https://github.com/github/super-linter"
  info "---------------------------------------------"
}
################################################################################
#### Function GetGitHubVars ####################################################
GetGitHubVars() {
  ##########
  # Prints #
  ##########
  info "--------------------------------------------"
  info "Gathering GitHub information..."

  ###############################
  # Get the Run test cases flag #
  ###############################
  if [ -z "${TEST_CASE_RUN}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    TEST_CASE_RUN="${DEFAULT_TEST_CASE_RUN}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  TEST_CASE_RUN="${TEST_CASE_RUN,,}"

  ##########################
  # Get the run local flag #
  ##########################
  if [ -z "${RUN_LOCAL}" ]; then
    ##################################
    # No flag passed, set to default #
    ##################################
    RUN_LOCAL="${DEFAULT_RUN_LOCAL}"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  RUN_LOCAL="${RUN_LOCAL,,}"

  #################################
  # Check if were running locally #
  #################################
  if [[ ${RUN_LOCAL} != "false" ]]; then
    ##########################################
    # We are running locally for a debug run #
    ##########################################
    info "NOTE: ENV VAR [RUN_LOCAL] has been set to:[true]"
    info "bypassing GitHub Actions variables..."

    ############################
    # Set the GITHUB_WORKSPACE #
    ############################
    if [ -z "${GITHUB_WORKSPACE}" ]; then
      GITHUB_WORKSPACE="${DEFAULT_WORKSPACE}"
    fi

    if [ ! -d "${GITHUB_WORKSPACE}" ]; then
      fatal "Provided volume is not a directory!"
    fi

    info "Linting all files in mapped directory:[${DEFAULT_WORKSPACE}]"

    # No need to touch or set the GITHUB_SHA
    # No need to touch or set the GITHUB_EVENT_PATH
    # No need to touch or set the GITHUB_ORG
    # No need to touch or set the GITHUB_REPO

    #################################
    # Set the VALIDATE_ALL_CODEBASE #
    #################################
    VALIDATE_ALL_CODEBASE="${DEFAULT_VALIDATE_ALL_CODEBASE}"
  else
    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_SHA}" ]; then
      error "Failed to get [GITHUB_SHA]!"
      fatal "[${GITHUB_SHA}]"
    else
      info "Successfully found:${F[W]}[GITHUB_SHA]${F[B]}, value:${F[W]}[${GITHUB_SHA}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_WORKSPACE}" ]; then
      error "Failed to get [GITHUB_WORKSPACE]!"
      fatal "[${GITHUB_WORKSPACE}]"
    else
      info "Successfully found:${F[W]}[GITHUB_WORKSPACE]${F[B]}, value:${F[W]}[${GITHUB_WORKSPACE}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_EVENT_PATH}" ]; then
      error "Failed to get [GITHUB_EVENT_PATH]!"
      fatal "[${GITHUB_EVENT_PATH}]"
    else
      info "Successfully found:${F[W]}[GITHUB_EVENT_PATH]${F[B]}, value:${F[W]}[${GITHUB_EVENT_PATH}]${F[B]}"
    fi

    ##################################################
    # Need to pull the GitHub Vars from the env file #
    ##################################################

    ######################
    # Get the GitHub Org #
    ######################
    GITHUB_ORG=$(jq -r '.repository.owner.login' <"${GITHUB_EVENT_PATH}")

    ########################
    # Fix SHA for PR event #
    ########################
    # Github sha on PR events is not the latest commit.
    # https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request
    if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
      GITHUB_SHA=$(jq -r .pull_request.head.sha <"$GITHUB_EVENT_PATH")
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_ORG}" ]; then
      error "Failed to get [GITHUB_ORG]!"
      fatal "[${GITHUB_ORG}]"
    else
      info "Successfully found:${F[W]}[GITHUB_ORG]${F[B]}, value:${F[W]}[${GITHUB_ORG}]"
    fi

    #######################
    # Get the GitHub Repo #
    #######################
    GITHUB_REPO=$(jq -r '.repository.name' <"${GITHUB_EVENT_PATH}")

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_REPO}" ]; then
      error "Failed to get [GITHUB_REPO]!"
      fatal "[${GITHUB_REPO}]"
    else
      info "Successfully found:${F[W]}[GITHUB_REPO]${F[B]}, value:${F[W]}[${GITHUB_REPO}]"
    fi
  fi

  ############################
  # Validate we have a value #
  ############################
  if [ "${MULTI_STATUS}" == "true" ] && [ -z "${GITHUB_TOKEN}" ] && [[ ${RUN_LOCAL} == "false" ]]; then
    error "Failed to get [GITHUB_TOKEN]!"
    error "[${GITHUB_TOKEN}]"
    error "Please set a [GITHUB_TOKEN] from the main workflow environment to take advantage of multiple status reports!"

    ################################################################################
    # Need to set MULTI_STATUS to false as we cant hit API endpoints without token #
    ################################################################################
    MULTI_STATUS='false'
  else
    info "Successfully found:${F[W]}[GITHUB_TOKEN]"
  fi

  ###############################
  # Convert string to lowercase #
  ###############################
  MULTI_STATUS="${MULTI_STATUS,,}"

  #######################################################################
  # Check to see if the multi status is set, and we have a token to use #
  #######################################################################
  if [ "${MULTI_STATUS}" == "true" ] && [ -n "${GITHUB_TOKEN}" ]; then
    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_REPOSITORY}" ]; then
      error "Failed to get [GITHUB_REPOSITORY]!"
      fatal "[${GITHUB_REPOSITORY}]"
    else
      info "Successfully found:${F[W]}[GITHUB_REPOSITORY]${F[B]}, value:${F[W]}[${GITHUB_REPOSITORY}]"
    fi

    ############################
    # Validate we have a value #
    ############################
    if [ -z "${GITHUB_RUN_ID}" ]; then
      error "Failed to get [GITHUB_RUN_ID]!"
      fatal "[${GITHUB_RUN_ID}]"
    else
      info "Successfully found:${F[W]}[GITHUB_RUN_ID]${F[B]}, value:${F[W]}[${GITHUB_RUN_ID}]"
    fi
  fi
}
################################################################################
#### Function CallStatusAPI ####################################################
CallStatusAPI() {
  ####################
  # Pull in the vars #
  ####################
  LANGUAGE="${1}" # language that was validated
  STATUS="${2}"   # success | error
  SUCCESS_MSG='No errors were found in the linting process'
  FAIL_MSG='Errors were detected, please view logs'
  MESSAGE='' # Message to send to status API

  debug "Calling Multi-Status API for $LANGUAGE with status $STATUS"

  ######################################
  # Check the status to create message #
  ######################################
  if [ "${STATUS}" == "success" ]; then
    # Success
    MESSAGE="${SUCCESS_MSG}"
  else
    # Failure
    MESSAGE="${FAIL_MSG}"
  fi

  ##########################################################
  # Check to see if were enabled for multi Status mesaages #
  ##########################################################
  if [ "${MULTI_STATUS}" == "true" ] && [ -n "${GITHUB_TOKEN}" ] && [ -n "${GITHUB_REPOSITORY}" ]; then

    # make sure we honor DISABLE_ERRORS
    if [ "${DISABLE_ERRORS}" == "true" ]; then
      STATUS="success"
    fi

    debug "URL: ${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"

    GITHUB_DOMAIN=$(echo "$GITHUB_DOMAIN" | cut -d '/' -f 3)

    ##############################################
    # Call the status API to create status check #
    ##############################################
    SEND_STATUS_CMD=$(
      curl -f -s --show-error -X POST \
        --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}" \
        -H 'accept: application/vnd.github.v3+json' \
        -H "authorization: Bearer ${GITHUB_TOKEN}" \
        -H 'content-type: application/json' \
        -d "{ \"state\": \"${STATUS}\",
        \"target_url\": \"https://${GITHUB_DOMAIN:-github.com}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}\",
        \"description\": \"${MESSAGE}\", \"context\": \"--> Linted: ${LANGUAGE}\"
      }" 2>&1
    )

    #######################
    # Load the error code #
    #######################
    ERROR_CODE=$?

    debug "Send status comd output: [$SEND_STATUS_CMD]"

    ##############################
    # Check the shell for errors #
    ##############################
    if [ "${ERROR_CODE}" -ne 0 ]; then
      # ERROR
      info "ERROR! Failed to call GitHub Status API!"
      info "ERROR:[${SEND_STATUS_CMD}]"
      # Not going to fail the script on this yet...
    fi
  fi
}
################################################################################
#### Function Footer ###########################################################
Footer() {
  info "----------------------------------------------"
  info "----------------------------------------------"
  info "The script has completed"
  info "----------------------------------------------"
  info "----------------------------------------------"

  ####################################################
  # Need to clean up the lanuage array of duplicates #
  ####################################################
  mapfile -t UNIQUE_LINTED_ARRAY < <(for LANG in "${LINTED_LANGUAGES_ARRAY[@]}"; do echo "${LANG}"; done | sort -u)
  export UNIQUE_LINTED_ARRAY # Workaround SC2034

  ##############################
  # Prints for errors if found #
  ##############################
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    ###########################
    # Build the error counter #
    ###########################
    ERROR_COUNTER="ERRORS_FOUND_${LANGUAGE}"

    ##################
    # Print if not 0 #
    ##################
    if [[ ${!ERROR_COUNTER} -ne 0 ]]; then
      # We found errors in the language
      ###################
      # Print the goods #
      ###################
      error "ERRORS FOUND${NC} in ${LANGUAGE}:[${!ERROR_COUNTER}]"

      #########################################
      # Create status API for Failed language #
      #########################################
      CallStatusAPI "${LANGUAGE}" "error"
      ######################################
      # Check if we validated the language #
      ######################################
    elif [[ ${!ERROR_COUNTER} -eq 0 ]]; then
      if CheckInArray "${LANGUAGE}"; then
        # No errors found when linting the language
        CallStatusAPI "${LANGUAGE}" "success"
      fi
    fi
  done

  ##################################
  # Exit with 0 if errors disabled #
  ##################################
  if [ "${DISABLE_ERRORS}" == "true" ]; then
    warn "Exiting with exit code:[0] as:[DISABLE_ERRORS] was set to:[${DISABLE_ERRORS}]"
    exit 0
  fi

  ###############################
  # Exit with 1 if errors found #
  ###############################
  # Loop through all languages
  for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
    # build the variable
    ERRORS_FOUND_LANGUAGE="ERRORS_FOUND_${LANGUAGE}"
    # Check if error was found
    if [[ ${!ERRORS_FOUND_LANGUAGE} -ne 0 ]]; then
      # Failed exit
      fatal "Exiting with errors found!"
    fi
  done

  ########################
  # Footer prints Exit 0 #
  ########################
  notice "All file(s) linted successfully with no errors detected"
  info "----------------------------------------------"
  # Successful exit
  exit 0
}
################################################################################
#### Function UpdateLoopsForImage ##############################################
UpdateLoopsForImage() {
  ######################################################################
  # Need to clean the array lists of the linters removed for the image #
  ######################################################################
  if [[ "${IMAGE}" == "slim" ]]; then
    #############################################
    # Need to remove linters for the slim image #
    #############################################
    REMOVE_ARRAY=("ARM" "CSHARP" "ENV" "POWERSHELL" "RUST_2015" "RUST_2018"
      "RUST_2021" "RUST_CLIPPY")

    # Remove from LANGUAGE_ARRAY
    echo "Removing Languages from LANGUAGE_ARRAY for slim image..."
    for REMOVE_LANGUAGE in "${REMOVE_ARRAY[@]}"; do
      for INDEX in "${!LANGUAGE_ARRAY[@]}"; do
        if [[ ${LANGUAGE_ARRAY[INDEX]} = "${REMOVE_LANGUAGE}" ]]; then
          echo "found item:[${REMOVE_LANGUAGE}], removing Language..."
          unset 'LANGUAGE_ARRAY[INDEX]'
        fi
      done
    done

    # Remove from LINTER_NAMES_ARRAY
    echo "Removing Linters from LINTER_NAMES_ARRAY for slim image..."
    for REMOVE_LINTER in "${REMOVE_ARRAY[@]}"; do
      for INDEX in "${!LINTER_NAMES_ARRAY[@]}"; do
        if [[ ${INDEX} = "${REMOVE_LINTER}" ]]; then
          echo "found item:[${REMOVE_LINTER}], removing linter..."
          unset 'LINTER_NAMES_ARRAY[$INDEX]'
        fi
      done
    done
  fi
}

# shellcheck disable=SC2317
cleanup() {
  local -ri EXIT_CODE=$?
  local LOG_FILE_PATH="${GITHUB_WORKSPACE}/${LOG_FILE}"
  debug "CREATE_LOG_FILE: ${CREATE_LOG_FILE}, LOG_FILE_PATH: ${LOG_FILE_PATH}"
  if [ "${CREATE_LOG_FILE}" = "true" ]; then
    debug "Creating log file: ${LOG_FILE_PATH}"
    sh -c "cat ${LOG_TEMP} >> ${LOG_FILE_PATH}" || true
  else
    debug "Skipping the log file creation"
  fi

  exit "${EXIT_CODE}"
  trap - 0 1 2 3 6 14 15
}
trap 'cleanup' 0 1 2 3 6 14 15

################################################################################
############################### MAIN ###########################################
################################################################################

##########
# Header #
##########
Header

############################################
# Create SSH agent and add key if provided #
############################################
SetupSshAgent
SetupGithubComSshKeys

################################################
# Need to update the loops for the image style #
################################################
UpdateLoopsForImage

##################################
# Get and print all version info #
##################################
GetLinterVersions

#######################
# Get GitHub Env Vars #
#######################
# Need to pull in all the GitHub variables
# needed to connect back and update checks
GetGitHubVars

########################################################
# Initialize variables that depend on GitHub variables #
########################################################
DEFAULT_ANSIBLE_DIRECTORY="${GITHUB_WORKSPACE}/ansible"                               # Default Ansible Directory
export DEFAULT_ANSIBLE_DIRECTORY                                                      # Workaround SC2034
DEFAULT_TEST_CASE_ANSIBLE_DIRECTORY="${GITHUB_WORKSPACE}/${TEST_CASE_FOLDER}/ansible" # Default Ansible directory when running test cases
export DEFAULT_TEST_CASE_ANSIBLE_DIRECTORY                                            # Workaround SC2034

############################
# Validate the environment #
############################
GetValidationInfo

#################################
# Get the linter rules location #
#################################
LinterRulesLocation

########################
# Get the linter rules #
########################
LANGUAGE_ARRAY_FOR_LINTER_RULES=("${LANGUAGE_ARRAY[@]}" "TYPESCRIPT_STANDARD_TSCONFIG")

for LANGUAGE in "${LANGUAGE_ARRAY_FOR_LINTER_RULES[@]}"; do
  debug "Loading rules for ${LANGUAGE}..."
  eval "GetLinterRules ${LANGUAGE} ${DEFAULT_RULES_LOCATION}"
done

# Load rules for a couple of special cases
GetStandardRules "javascript"
GetStandardRules "typescript"

##########################
# Define linter commands #
##########################
declare -A LINTER_COMMANDS_ARRAY
LINTER_COMMANDS_ARRAY['OPENAPI']="spectral lint -r ${OPENAPI_LINTER_RULES} -D"

debug "--- Linter commands ---"
debug "-----------------------"
for i in "${!LINTER_COMMANDS_ARRAY[@]}"; do
  debug "Linter key: $i, command: ${LINTER_COMMANDS_ARRAY[$i]}"
done
debug "---------------------------------------------"

#################################
# Check for SSL cert and update #
#################################
CheckSSLCert


###########################################
# Build the list of files for each linter #
###########################################
BuildFileList "${VALIDATE_ALL_CODEBASE}" "${TEST_CASE_RUN}" "${ANSIBLE_DIRECTORY}"

#####################################
# Run additional Installs as needed #
#####################################
RunAdditionalInstalls

###############
# Run linters #
###############
##EDITORCONFIG_FILE_PATH="${GITHUB_WORKSPACE}"/.editorconfig

####################################
# Print ENV before running linters #
####################################
debug "--- ENV (before running linters) ---"
debug "------------------------------------"
PRINTENV=$(printenv | sort)
debug "ENV:"
debug "${PRINTENV}"
debug "------------------------------------"

for LANGUAGE in "${LANGUAGE_ARRAY[@]}"; do
  debug "Running linter for the ${LANGUAGE} language..."
  VALIDATE_LANGUAGE_VARIABLE_NAME="VALIDATE_${LANGUAGE}"
  debug "Setting VALIDATE_LANGUAGE_VARIABLE_NAME to ${VALIDATE_LANGUAGE_VARIABLE_NAME}..."
  VALIDATE_LANGUAGE_VARIABLE_VALUE="${!VALIDATE_LANGUAGE_VARIABLE_NAME}"
  debug "Setting VALIDATE_LANGUAGE_VARIABLE_VALUE to ${VALIDATE_LANGUAGE_VARIABLE_VALUE}..."

  if [ "${VALIDATE_LANGUAGE_VARIABLE_VALUE}" = "true" ]; then
    LINTER_NAME="${LINTER_NAMES_ARRAY["${LANGUAGE}"]}"
    if [ -z "${LINTER_NAME}" ]; then
      fatal "Cannot find the linter name for ${LANGUAGE} language."
    else
      debug "Setting LINTER_NAME to ${LINTER_NAME}..."
    fi

    LINTER_COMMAND="${LINTER_COMMANDS_ARRAY["${LANGUAGE}"]}"
    if [ -z "${LINTER_COMMAND}" ]; then
      fatal "Cannot find the linter command for ${LANGUAGE} language."
    else
      debug "Setting LINTER_COMMAND to ${LINTER_COMMAND}..."
    fi

    FILE_ARRAY_VARIABLE_NAME="FILE_ARRAY_${LANGUAGE}"
    debug "Setting FILE_ARRAY_VARIABLE_NAME to ${FILE_ARRAY_VARIABLE_NAME}..."

    # shellcheck disable=SC2125
    LANGUAGE_FILE_ARRAY="${FILE_ARRAY_VARIABLE_NAME}"[@]
    debug "${FILE_ARRAY_VARIABLE_NAME} file array contents: ${!LANGUAGE_FILE_ARRAY}"

    debug "Invoking ${LINTER_NAME} linter. TEST_CASE_RUN: ${TEST_CASE_RUN}"
    LintCodebase "${LANGUAGE}" "${LINTER_NAME}" "${LINTER_COMMAND}" "${FILTER_REGEX_INCLUDE}" "${FILTER_REGEX_EXCLUDE}" "${TEST_CASE_RUN}" "${!LANGUAGE_FILE_ARRAY}"
  fi
done

##########
# Footer #
##########
Footer

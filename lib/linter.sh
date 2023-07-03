##HTML_FILE_NAME=".htmlhintrc"
# shellcheck disable=SC2034  # Variable is referenced indirectly
JAVA_FILE_NAME="${JAVA_FILE_NAME:-sun_checks.xml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
JAVASCRIPT_ES_FILE_NAME="${JAVASCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
JAVASCRIPT_DEFAULT_STYLE="${JAVASCRIPT_DEFAULT_STYLE:-standard}"
JAVASCRIPT_STYLE_NAME='' # Variable for the style
JAVASCRIPT_STYLE=''      # Variable for the style
# shellcheck disable=SC2034  # Variable is referenced indirectly
JAVASCRIPT_STANDARD_FILE_NAME="${JAVASCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
##JSCPD_FILE_NAME="${JSCPD_CONFIG_FILE:-.jscpd.json}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
JSX_FILE_NAME="${JAVASCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
##KUBERNETES_KUBECONFORM_OPTIONS="${KUBERNETES_KUBECONFORM_OPTIONS:-null}"
##TERRAFORM_TERRASCAN_FILE_NAME="${TERRAFORM_TERRASCAN_CONFIG_FILE:-terrascan.toml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
##NATURAL_LANGUAGE_FILE_NAME="${NATURAL_LANGUAGE_CONFIG_FILE:-.textlintrc}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
TSX_FILE_NAME="${TYPESCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
TYPESCRIPT_DEFAULT_STYLE="${TYPESCRIPT_DEFAULT_STYLE:-ts-standard}"
TYPESCRIPT_STYLE_NAME='' # Variable for the style
TYPESCRIPT_STYLE=''      # Variable for the style
# shellcheck disable=SC2034  # Variable is referenced indirectly
TYPESCRIPT_ES_FILE_NAME="${TYPESCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
TYPESCRIPT_STANDARD_FILE_NAME="${TYPESCRIPT_ES_CONFIG_FILE:-.eslintrc.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
TYPESCRIPT_STANDARD_TSCONFIG_FILE_NAME="${TYPESCRIPT_STANDARD_TSCONFIG_FILE:-tsconfig.json}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
USE_FIND_ALGORITHM="${USE_FIND_ALGORITHM:-false}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
YAML_FILE_NAME="${YAML_CONFIG_FILE:-.yaml-lint.yml}"
# shellcheck disable=SC2034  # Variable is referenced indirectly
YAML_ERROR_ON_WARNING="${YAML_ERROR_ON_WARNING:-false}"
##if [ "${JAVASCRIPT_DEFAULT_STYLE}" == "prettier" ]; then
  # Set to prettier
  ##JAVASCRIPT_STYLE_NAME='JAVASCRIPT_PRETTIER'
  ##JAVASCRIPT_STYLE='prettier'
##else
  # Default to standard
  JAVASCRIPT_STYLE_NAME='JAVASCRIPT_STANDARD'
  JAVASCRIPT_STYLE='standard'
##fi

#################################################
# Parse if we are using JS standard or prettier #
#################################################
# Remove spaces
##if [ "${TYPESCRIPT_DEFAULT_STYLE}" == "prettier" ]; then
  # Set to prettier
  ##TYPESCRIPT_STYLE_NAME='TYPESCRIPT_PRETTIER'
  ##TYPESCRIPT_STYLE='prettier'
##else
  # Default to standard
  TYPESCRIPT_STYLE_NAME='TYPESCRIPT_STANDARD'
  TYPESCRIPT_STYLE='ts-standard'
##fi

##################
# Language array #
##################
LANGUAGE_ARRAY=('ANSIBLE' 'ARM' 'BASH' 'BASH_EXEC'
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

##LINTER_COMMANDS_ARRAY['GO']="golangci-lint run --fast -c ${GO_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['GOOGLE_JAVA_FORMAT']="java -jar /usr/bin/google-java-format --dry-run --set-exit-if-changed"
LINTER_COMMANDS_ARRAY['GROOVY']="npm-groovy-lint -c ${GROOVY_LINTER_RULES} --failon warning --no-insight"
##LINTER_COMMANDS_ARRAY['HTML']="htmlhint --config ${HTML_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['JAVA']="java -jar /usr/bin/checkstyle -c ${JAVA_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JAVASCRIPT_ES']="eslint --no-eslintrc -c ${JAVASCRIPT_ES_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JAVASCRIPT_STANDARD']="standard ${JAVASCRIPT_STANDARD_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['JAVASCRIPT_PRETTIER']="prettier --check"
##LINTER_COMMANDS_ARRAY['JSCPD']="jscpd --config ${JSCPD_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['JSON']="eslint --no-eslintrc -c ${JAVASCRIPT_ES_LINTER_RULES} --ext .json"
LINTER_COMMANDS_ARRAY['JSONC']="eslint --no-eslintrc -c ${JAVASCRIPT_ES_LINTER_RULES} --ext .json5,.jsonc"
LINTER_COMMANDS_ARRAY['JSX']="eslint --no-eslintrc -c ${JSX_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['KOTLIN']="ktlint"
##LINTER_COMMANDS_ARRAY['TERRAFORM_FMT']="terraform fmt -check -diff"
##LINTER_COMMANDS_ARRAY['TERRAFORM_TFLINT']="tflint -c ${TERRAFORM_TFLINT_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['TERRAFORM_TERRASCAN']="terrascan scan -i terraform -t all -c ${TERRAFORM_TERRASCAN_LINTER_RULES} -f"
##LINTER_COMMANDS_ARRAY['TERRAGRUNT']="terragrunt hclfmt --terragrunt-check --terragrunt-log-level error --terragrunt-hclfmt-file"
LINTER_COMMANDS_ARRAY['TSX']="eslint --no-eslintrc -c ${TSX_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TYPESCRIPT_ES']="eslint --no-eslintrc -c ${TYPESCRIPT_ES_LINTER_RULES}"
LINTER_COMMANDS_ARRAY['TYPESCRIPT_STANDARD']="ts-standard --parser @typescript-eslint/parser --plugin @typescript-eslint/eslint-plugin --project ${TYPESCRIPT_STANDARD_TSCONFIG_LINTER_RULES} ${TYPESCRIPT_STANDARD_LINTER_RULES}"
##LINTER_COMMANDS_ARRAY['TYPESCRIPT_PRETTIER']="prettier --check"
##LINTER_COMMANDS_ARRAY['XML']="xmllint"
##if [ "${YAML_ERROR_ON_WARNING}" == 'false' ]; then
##  LINTER_COMMANDS_ARRAY['YAML']="yamllint -c ${YAML_LINTER_RULES} -f parsable"
##else
##  LINTER_COMMANDS_ARRAY['YAML']="yamllint --strict -c ${YAML_LINTER_RULES} -f parsable"

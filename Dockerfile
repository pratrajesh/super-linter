###########################################
###########################################
## Dockerfile to run GitHub Super-Linter ##
###########################################
###########################################

##################
# Get base image #
##################
FROM python:3.11.4-alpine3.17 as base_image

####################
# Run APK installs #
####################
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    npm nodejs-current
  
########################################
# Copy dependencies files to container #
########################################
COPY dependencies/* /

###################################################################
# Install Dependencies                                            #
# The chown fixes broken uid/gid in ast-types-flow dependency     #
# (see https://github.com/github/super-linter/issues/3901)        #
###################################################################
RUN npm install && chown -R "$(id -u)":"$(id -g)" node_modules

# Source: https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
# Store the key here because the above host is sometimes down, and breaks our builds
COPY dependencies/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub

################################
# Install Bash-Exec #
################################
COPY --chmod=555 scripts/bash-exec.sh /usr/bin/bash-exec

#################################################
# Install Raku and additional Edge dependencies #
#################################################
RUN apk add --no-cache rakudo zef

################################################################################
# Grab small clean image to build python packages ##############################
################################################################################
FROM python:3.11.4-alpine3.17 as python_builder
RUN apk add --no-cache bash g++ git libffi-dev
COPY dependencies/python/ /stage
WORKDIR /stage
RUN ./build-venvs.sh

################################################################################
# Grab small clean image to build slim ###################################
################################################################################
FROM alpine:3.18.2 as slim

############################
# Get the build arguements #
############################
ARG BUILD_DATE
ARG BUILD_REVISION
ARG BUILD_VERSION

#########################################
# Label the instance and set maintainer #
#########################################
LABEL com.github.actions.name="GitHub Super-Linter" \
    com.github.actions.description="Lint your code base with GitHub Actions" \
    com.github.actions.icon="code" \
    com.github.actions.color="red" \
    maintainer="GitHub DevOps <github_devops@github.com>" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$BUILD_REVISION \
    org.opencontainers.image.version=$BUILD_VERSION \
    org.opencontainers.image.authors="GitHub DevOps <github_devops@github.com>" \
    org.opencontainers.image.url="https://github.com/github/super-linter" \
    org.opencontainers.image.source="https://github.com/github/super-linter" \
    org.opencontainers.image.documentation="https://github.com/github/super-linter" \
    org.opencontainers.image.vendor="GitHub" \
    org.opencontainers.image.description="Lint your code base with GitHub Actions"

#################################################
# Set ENV values used for debugging the version #
#################################################
ENV BUILD_DATE=$BUILD_DATE
ENV BUILD_REVISION=$BUILD_REVISION
ENV BUILD_VERSION=$BUILD_VERSION
ENV IMAGE="slim"

# Source: https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
# Store the key here because the above host is sometimes down, and breaks our builds
COPY dependencies/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub

###############
# Install Git #
###############
RUN apk add --no-cache bash git git-lfs

#################################
# Copy the libraries into image #
#################################
COPY --from=base_image /usr/bin/ /usr/bin/
COPY --from=base_image /usr/local/bin/ /usr/local/bin/
COPY --from=base_image /usr/local/lib/ /usr/local/lib/
COPY --from=base_image /usr/local/share/ /usr/local/share/
COPY --from=base_image /usr/local/include/ /usr/local/include/
COPY --from=base_image /usr/lib/ /usr/lib/
COPY --from=base_image /usr/share/ /usr/share/
COPY --from=base_image /lib/ /lib/
COPY --from=base_image /bin/ /bin/
COPY --from=base_image /node_modules/ /node_modules/
COPY --from=python_builder /venvs/yq/ /venvs/yq/

########################################
# Add node packages to path and dotnet #
########################################
ENV PATH="${PATH}:/node_modules/.bin"

###############################
# Add python packages to path #
###############################
ENV PATH="${PATH}:/venvs/yq/bin"

#############################
# Copy scripts to container #
#############################
COPY lib /action/lib

##################################
# Copy linter rules to container #
##################################
COPY TEMPLATES /action/lib/.automation

################
# Pull in libs #
################
COPY --from=base_image /usr/libexec/ /usr/libexec/

################################################
# Run to build version file and validate image #
################################################
RUN ACTIONS_RUNNER_DEBUG=true WRITE_LINTER_VERSIONS_FILE=true IMAGE="${IMAGE}" /action/lib/linter.sh

######################
# Set the entrypoint #
######################
ENTRYPOINT ["/action/lib/linter.sh"]

################################################################################
# Grab small clean image to build standard ###############################
################################################################################
FROM slim as standard

###############
# Set up args #
###############
ARG GITHUB_TOKEN
ARG PWSH_VERSION='latest'
ARG PWSH_DIRECTORY='/usr/lib/microsoft/powershell'
ARG PSSA_VERSION='1.21.0'
# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH

################
# Set ENV vars #
################
ENV ARM_TTK_PSD1="/usr/lib/microsoft/arm-ttk/arm-ttk.psd1"
ENV IMAGE="standard"
ENV PATH="${PATH}:/var/cache/dotnet/tools:/usr/share/dotnet"

#########################
# Install dotenv-linter #
#########################
##COPY --from=dotenv-linter /dotenv-linter /usr/bin/

###################################
# Install DotNet and Dependencies #
###################################
COPY scripts/install-dotnet.sh /
RUN /install-dotnet.sh && rm -rf /install-dotnet.sh

##############################
# Install rustfmt & clippy   #
##############################
##ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
##COPY scripts/install-rustfmt.sh /
##RUN /install-rustfmt.sh && rm -rf /install-rustfmt.sh

#########################################
# Install Powershell + PSScriptAnalyzer #
#########################################
COPY scripts/install-pwsh.sh /
RUN --mount=type=secret,id=GITHUB_TOKEN /install-pwsh.sh && rm -rf /install-pwsh.sh

#############################################################
# Install Azure Resource Manager Template Toolkit (arm-ttk) #
#############################################################
COPY scripts/install-arm-ttk.sh /
RUN --mount=type=secret,id=GITHUB_TOKEN /install-arm-ttk.sh && rm -rf /install-arm-ttk.sh

########################################################################################
# Run to build version file and validate image again because we installed more linters #
########################################################################################
RUN ACTIONS_RUNNER_DEBUG=true WRITE_LINTER_VERSIONS_FILE=true IMAGE="${IMAGE}" /action/lib/linter.sh

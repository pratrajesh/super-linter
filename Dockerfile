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

################################
# Install Bash-Exec #
################################
COPY --chmod=555 scripts/bash-exec.sh /usr/bin/bash-exec

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

###############
# Install Git #
###############
RUN apk add --no-cache bash git git-lfs

#################################
# Copy the libraries into image #
#################################
COPY --from=base_image /usr/bin/ /usr/bin/
COPY --from=base_image /usr/local/bin/ /usr/local/bin/
COPY --from=base_image /usr/local/share/ /usr/local/share/
COPY --from=base_image /usr/local/include/ /usr/local/include/
COPY --from=base_image /usr/lib/ /usr/lib/
COPY --from=base_image /usr/share/ /usr/share/
COPY --from=base_image /lib/ /lib/
COPY --from=base_image /bin/ /bin/
COPY --from=base_image /node_modules/ /node_modules/

##RUN ls -R /usr/local/lib

RUN du -sh /usr/bin/*/

########################################
# Add node packages to path and dotnet #
########################################
ENV PATH="${PATH}:/node_modules/.bin"

#############################
# Copy scripts to container #
#############################
COPY lib /action/lib

##################################
# Copy linter rules to container #
##################################
COPY TEMPLATES /action/lib/.automation

################################################
# Run to build version file and validate image #
################################################
RUN ACTIONS_RUNNER_DEBUG=true WRITE_LINTER_VERSIONS_FILE=true IMAGE="${IMAGE}" /action/lib/linter.sh

######################
# Set the entrypoint #
######################
ENTRYPOINT ["/action/lib/linter.sh"]

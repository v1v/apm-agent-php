#!/usr/bin/env sh
set -x

###################
#### VARIABLES ####
###################
BUILD_RELEASES_FOLDER=build/releases

###################
#### FUNCTIONS ####
###################
download() {
    package=$1
    folder=$2
    url=$3
    mkdir -p "${folder}"
    wget -q "${url}/${package}" -O "${folder}/${package}"
    wget -q "${url}/${package}.sha512" -O "${folder}/${package}.sha512"
    cd "${folder}" || exit
    shasum -a 512 -c "${package}.sha512"
    cd - || exit
}

validate_if_agent_is_uninstalled() {
    ## Validate if the elastic php agent has been uninstalled
    php -m
    if php -m | grep -q "Unable to load dynamic library '/opt/elastic/apm-agent-php/extensions"  ; then
        echo 'Extension has not been uninstalled.'
        exit 1
    fi
    if php -m | grep -q 'elastic' ; then
        echo 'Extension has not been uninstalled.'
        exit 1
    fi
}

validate_if_agent_is_enabled() {
    ## Validate if the elastic php agent is enabled
    if ! php -m | grep -q 'elastic' ; then
        echo 'Extension has not been installed.'
        exit 1
    fi
}

validate_installation() {
    ## Validate the installation works as expected with composer
    composer install
    syslogd
    if ! composer run-script run_component_tests ; then
        echo 'Something bad happened when running the tests, see the output from the syslog'
        cat /var/log/messages
        exit 1
    fi
}

##############
#### MAIN ####
##############
if [ "${TYPE}" = "release-github" ] ; then
    PACKAGE=apm-agent-php_${VERSION}_all.apk
    download "${PACKAGE}" "${BUILD_RELEASES_FOLDER}" "${GITHUB_RELEASES_URL}/v${VERSION}"
    apk add --allow-untrusted --verbose --no-cache "${BUILD_RELEASES_FOLDER}/${PACKAGE}"
elif [ "${TYPE}" == "agent-upgrade" ] ; then
    PACKAGE=apm-agent-php_${VERSION}_all.apk
    download "${PACKAGE}" "${BUILD_RELEASES_FOLDER}" "${GITHUB_RELEASES_URL}/v${VERSION}"
    apk add --allow-untrusted --verbose --no-cache "${BUILD_RELEASES_FOLDER}/${PACKAGE}"
else
    ## Install apk package and configure the agent accordingly
    apk add --allow-untrusted --verbose --no-cache build/packages/*.apk
fi

validate_if_agent_is_enabled

if [ "${TYPE}" == "agent-upgrade" ] ; then
    echo 'Validate installation runs after the agent upgrade.'
else
    validate_installation
fi

## Validate the uninstallation works as expected
set -ex
if [ "${TYPE}" = "apk-uninstall" ] ; then
    apk del --verbose --no-cache "${PACKAGE}"
    validate_if_agent_is_uninstalled
elif [ "${TYPE}" == "agent-upgrade" ] ; then
    ## Upgrade the agent version with the apk package and configure the agent accordingly
    apk add --allow-untrusted --verbose --no-cache build/packages/*.apk

    ## Validate agent is enabled
    validate_if_agent_is_enabled

    ## Run some tests
    validate_installation
fi

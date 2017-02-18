#!/bin/bash

set -e

# Credits:
#
# Inspired by superlumic & macisble
#
# - https://github.com/superlumic/superlumic/blob/master/superlumic
# - https://github.com/macsible/macsible/blob/master/init.sh

DIR="$(command cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/common.sh

# DEFAULTS

sudo -v
export ANSIBLE_ASK_SUDO_PASS=True
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

username=${1-$(whoami)}

# ------------------------------------------------------------------------------

# @function    : provision
# @description : provisions a machine using ansible
#
# @params {string} $1   the playbook name to use

function provision {

    # update existing sudo time stamp until we are finished

    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    pre_provision

    playbook_prefix="users/$1"

    # Determine which type of user configuration we have
    # by looking for playbooks conforming to the structure
    # outlined below
    #
    # - <username>.yml
    # - <username>/playbook.yml

    if [ -f "$playbook_prefix.yml" ]; then

        playbook_path="playbook_prefix.yml"

    elif [ -f "$playbook_prefix/playbook.yml" ]; then

        playbook_path="$playbook_prefix/playbook.yml"

    elif [ -f "users/default.yml" ]; then
        playbook_path="users/default.yml"
        username="default"
    else
        triggerError "No playbook for $1 found"
    fi

    setStatusMessage "running playbook for \"$1\" ( $playbook_path )"

    # install roles required for provisioning
    #
    # common external roles are installed by default followed by
    # user specific roles
    #
    # - requirements.yml
    # - <username>/requirements.yml

    installRoles "common" "requirements.yml"
    installRoles $1 "$playbook_prefix/requirements.yml"

    ansible-playbook -i "localhost," playbook.yml --extra-vars "cli_playbook_path=\"$playbook_path\""

}

provision $username

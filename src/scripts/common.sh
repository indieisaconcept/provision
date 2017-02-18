#!/bin/bash

# Credits:
#
# Inspired by superlumic & macisble
#
# - https://github.com/superlumic/superlumic/blob/master/superlumic
# - https://github.com/macsible/macsible/blob/master/init.sh

BGreen='\e[1;32m' # Green
BRed='\e[1;31m'   # Red
Color_Off='\e[0m' # Text Reset

# @function    : setStatusMessage
# @description : prints a status message to stdout
#
# @params {string} $1 	the message to print

function setStatusMessage {
    printf "${IRed} --> ${BGreen}$1${Color_Off}\n" 1>&2
}

# ------------------------------------------------------------------------------

# @function    : triggerError
# @description : prints a an error message to stdout and terminate
#				 with a non-zero exit code
#
# @params {string} $1 	the message to print

function triggerError {
    printf "${BRed} --> $1 ${Color_Off}\n" 1>&2
    exit 1
}

# ------------------------------------------------------------------------------

# @function    : exists
# @description : check whether a command exists - returns 0 if it does, 
#				 1 if it does not
#
# @params {string} $1 	the command to check

function exists {
  if command -v $1 >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------

# @function    : installRoles
# @description : install ansible roles via ansible-galaxy
#
# @params {string} $1 	a username
# @params {string} $2 	the path to the requirements file

function installRoles {
    if [ -f "$2" ]; then
    	setStatusMessage "installing external roles for \"$1\""
    	ansible-galaxy install -r $2 -p "roles/external"
    fi
}

# ------------------------------------------------------------------------------

# @function    : install_clt
# @description : install commandline tooling for OSX
#
# @credit	   : https://github.com/boxcutter/osx/blob/master/script/xcode-cli-tools.sh

function install_clt {
    # Get and install Xcode CLI tools
    OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')

    # on 10.9+, we can leverage SUS to get the latest CLI tools
    if [ "$OSX_VERS" -ge 9 ]; then
        # create the placeholder file that's checked by CLI updates' .dist code
        # in Apple's SUS catalog
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        # find the CLI Tools update
        PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
        # install it
        softwareupdate -i "$PROD" --verbose
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # on 10.7/10.8, we instead download from public download URLs, which can be found in
    # the dvtdownloadableindex:
    # https://devimages.apple.com.edgekey.net/downloads/xcode/simulators/index-3905972D-B609-49CE-8D06-51ADC78E07BC.dvtdownloadableindex
    else
        [ "$OSX_VERS" -eq 7 ] && DMGURL=http://devimages.apple.com.edgekey.net/downloads/xcode/command_line_tools_for_xcode_os_x_lion_april_2013.dmg
        [ "$OSX_VERS" -eq 7 ] && ALLOW_UNTRUSTED=-allowUntrusted
        [ "$OSX_VERS" -eq 8 ] && DMGURL=http://devimages.apple.com.edgekey.net/downloads/xcode/command_line_tools_for_osx_mountain_lion_april_2014.dmg

        TOOLS=clitools.dmg
        curl "$DMGURL" -o "$TOOLS"
        TMPMOUNT=`/usr/bin/mktemp -d /tmp/clitools.XXXX`
        hdiutil attach "$TOOLS" -mountpoint "$TMPMOUNT"
        installer $ALLOW_UNTRUSTED -pkg "$(find $TMPMOUNT -name '*.mpkg')" -target /
        hdiutil detach "$TMPMOUNT"
        rm -rf "$TMPMOUNT"
        rm "$TOOLS"
        exit
    fi
}

# ------------------------------------------------------------------------------

# @function    : pre_provision
# @description : executes tasks which are pre-requisits for the provision
#                process such as installing dependencies ( eg: ansible )

function pre_provision {

    if [[ ! -f "/Library/Developer/CommandLineTools/usr/bin/clang" ]]; then
        setStatusMessage "installing CLI tools"
        install_clt
    fi

    if ! exists pip; then
        setStatusMessage "installing PIP"
        sudo easy_install --quiet pip
    fi

    if ! exists ansible; then
        setStatusMessage "installing Ansible"
        pip install --upgrade setuptools --user python
        sudo pip install -q ansible
    fi

}
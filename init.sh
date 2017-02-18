#!/bin/bash

directory=~/.provision
remote=https://github.com/indieisaconcept/provision.git
username=$1

# assumes we are in the current project directory
# and if not we are actually installing

if [[ ! -d ".git" ]]; then

	if [ -d "$directory" ]; then
		cd $directory;
		git pull -q;
	else
		git clone -q $remote $directory && cd $directory;
	fi

else
	git pull -q;
fi

./src/scripts/provision.sh $username;
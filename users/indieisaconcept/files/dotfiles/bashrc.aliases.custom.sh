#!/usr/bin/env bash

alias ap="cd /volumes/Documents/work/autopilot/projects"

function hydrate () {
    `cd /volumes/Documents/work/autopilot/projects/api || exit; \
    ~/Desktop/rehydrate-elasticsearch.sh "$@";`
}

alias hydrate="hydrate"

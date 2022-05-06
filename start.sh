#!/bin/bash

# clone target project
if [ -d "${HOME}/project" ] 
then
    rm -rf "${HOME}/project/*"
fi
cd "${HOME}/project"
git clone --quiet ${GIT_REPO} .

# try create links data
if [ -d "${DATA_MNT}" ] 
then
    ln -s "${DATA_MNT}" "${HOME}/project/data" 
fi

# start 
crontab-ui --autosave
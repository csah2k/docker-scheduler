#!/bin/bash

# clone target project
cd "${HOME}/project"
git clone --quiet ${GIT_REPO} . || git pull

# try create links data
if [ -d "${DATA_MNT}" ] 
then
    ln -s "${DATA_MNT}" "${HOME}/project/data" 
fi

# start 
crontab-ui --autosave
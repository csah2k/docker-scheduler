#!/bin/bash

# clone target project
git config --global --add safe.directory "${HOME}/project"
cd "${HOME}/project"
git clone --quiet ${GIT_REPO} . || git pull

# try create links data
if [ -d "${DATA_MNT}" ] 
then
    ln -s "${DATA_MNT}" "${HOME}/project/data" 
fi

# try to clean or create log folder
if [ -d "${CRON_DB_PATH}/logs" ] 
then
    rm -rf "${CRON_DB_PATH}/logs/*"
else
    mkdir -p "${CRON_DB_PATH}/logs"
fi

# start crontab
service cron start

# start web ui
crontab-ui --autosave
#!/bin/bash

HTTP_PROTOCOL="http"
if [ ! -z "${SSL_CERT}" ]; then
    HTTP_PROTOCOL="https"
fi

if [ -z "${BASIC_AUTH_USER}" ]; then
    wget -O /dev/null --no-verbose --no-check-certificate --tries=1 ${HTTP_PROTOCOL}://localhost:${PORT}${BASE_URL}stdout || exit 1
else 
    wget -O /dev/null --no-verbose --no-check-certificate --tries=1 ${HTTP_PROTOCOL}://${BASIC_AUTH_USER}:${BASIC_AUTH_PWD}@localhost:${PORT}${BASE_URL}stdout || exit 1
fi

initd=`service cron status | grep "cron is running" | wc -l | awk '{ print $1 }'`
if [ $initd = "1" ]; then
    echo "CRONTAB RUNNING"
    exit 0
else 
    echo "CRONTAB STOPPED"
    exit 1
fi

exit 0
#!/bin/bash

HTTP_PROTOCOL="http"
if [ ! -z "${SSL_CERT}" ]; then
    HTTP_PROTOCOL="https"
fi

if [ -z "${BASIC_AUTH_USER}" ]; then
    wget -O- --no-verbose --no-check-certificate --tries=1 ${HTTP_PROTOCOL}://localhost:${PORT}${BASE_URL} || exit 1
else 
    wget -O- --no-verbose --no-check-certificate --tries=1 ${HTTP_PROTOCOL}://${BASIC_AUTH_USER}:${BASIC_AUTH_PWD}@localhost:${PORT}${BASE_URL} || exit 1
fi

exit 0
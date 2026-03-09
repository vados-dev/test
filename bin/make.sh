#!/bin/bash

export BUILD_DIR="/var/www/ros.vados.ru"
set -e
##export BUILD_DIR
#make checksums 2>/dev/null
cd ${BUILD_DIR} && \
 make checksums 2>/dev/null
#> "$amsBin/checksums.log"

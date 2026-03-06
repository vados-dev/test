#!/bin/sh

set -e

echo "$@" >> log.txt
#exit 0

md5sum $(find -name '*.rsc' | sort) | \
	sed -e "s| \./||" -e 's|.rsc$||' | \
	jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add'

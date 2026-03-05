# Makefile

BUILD_DIR       = $(shell pwd)
HTML_DIR        := $(BUILD_DIR:/html)

HTML_PATH       := $(realpath $(BUILD_DIR) html)

ALL_RSC		:= $(wildcard *.rsc */*.rsc)
GFUNC		:= $(ALL_RSC:AM-GlobaFunc.rsc)

#GEN_RSC		:= $(wildcard *.capsman.rsc *.local.rsc *.wifi.rsc)
#MARKDOWN	:= $(wildcard *.md doc/*.md doc/mod/*.md)
#HTML		:= $(MARKDOWN:.md=.html)
CM_FIND         := $(shell find -name '*.rsc' | sort 2>/dev/null)
#CHECKSUM        := $(shell md5sum $(CM_FIND) 2>/dev/null)
#SUM_SED         := $(shell sed -e "s| \./||" -e 's|.rsc$||' 2>/dev/null)
#SUM_JQ          := $(shell jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add' 2>/dev/null)
DATE            ?= $(shell (date '+%T %d.%m.%Y'))
DTSTAMP         ?= $(shell (date '+%Y%d%m%H%M%S'))
VERSION         ?= $(shell git symbolic-ref --short HEAD 2>/dev/null)/$(shell git rev-list --count HEAD 2>/dev/null)/$(shell git rev-parse --short=8 HEAD 2>/dev/null)
OWNER           ?= $(shell whoami)
export BUILD_DIR DATE VERSION

.PHONY: all checksums
# $(html)
#incl fname

#checksums commitinfo docs rsc clean
all: checksums
# $(html)
# incl fname
#%.md5: FORCE
#   @$(eval CHECKSUM := $(shell md5sum $*))$(if $(filter-out $(shell cat $@ 2>/dev/null),$(CHECKSUM)),echo $(CHECKSUM) > $@)
#md5sum: $1
#    @SUM=$$(md5sum $1 | cut -d' ' -f 1); \
#    echo $$SUM; > $2

#checksums docs rsc

disp:
	cd $(html) && \
	ls -la .
	cd $(BUILD_DIR) && \
	ls -la .
	cd $(HTML_PATH) && \
	ls -la .

checksums: checksums.json

checksums.json:				
				$(ALL_RSC) | \
				$(shell md5sum $(CM_FIND)) | \
    			sed -e "s| \./||" -e "s|.rsc$$$||" | \
    			jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add' $< > $@

#		$(SUM_SED) | \
#		$(SUM_JQ) > $@
#		md5sum $(find -name '*.rsc' | sort) | 
#		set -e \
#		$(SUM_SED) $<$(ALL_RSC) > html/$@
#	sed -e "s| \./||" -e 's|.rsc$||' | \
#	jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add' $< > html/$@

#contrib/checksums.sh $(ALL_RSC)
#	contrib/checksums.sh > $@

commitinfo: global-functions.rsc
	contrib/commitinfo.sh $< > $<~
	mv $<~ $<

docs: $(HTML)

%.html: %.md general/style.css contrib/html.sh contrib/html.sh.d/head.html contrib/html.sh.d/foot.html
	contrib/html.sh $< > $@

rsc: $(GEN_RSC)

%.capsman.rsc: %.template.rsc contrib/template-capsman.sh
	contrib/template-capsman.sh $< > $@

%.local.rsc: %.template.rsc contrib/template-local.sh
	contrib/template-local.sh $< > $@

%.wifi.rsc: %.template.rsc contrib/template-wifi.sh
	contrib/template-wifi.sh $< > $@

clean:
	rm -f $(HTML) checksums.json
	make -C contrib/ clean

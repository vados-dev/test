# Makefile

BUILD_DIR       = $(shell pwd)
HTML_DIR        := $(BUILD_DIR:/html)

ALL_RSC         := $(wildcard html/*.rsc html/*/*.rsc)

#CM_FIND         := $(ALL_RSC:$(shell find -name '*.rsc' | sort 2>/dev/null),$(shell md5sum $*),echo )
#MD5SUM          := $(wildcard html/*.rsc html/*/*.rsc)
#RSC             := $(MD5SUM:.rsc=@$(shell bin/checksums.sh) > $@)
#MD5SUMS         := $(shell md5sum $(CM_FIND) $(SUMS_RSC) 2>/dev/null)
#@$(eval CHECKSUM := $(shell md5sum $*))$(if $(filter-out $(shell cat $@ 2>/dev/null),$(CHECKSUM)),echo $(CHECKSUM) > $@)
DATE            ?= $(shell (date '+%T %d.%m.%Y'))
DTSTAMP         ?= $(shell (date '+%Y%d%m%H%M%S'))
VERSION         ?= $(shell git symbolic-ref --short HEAD 2>/dev/null)/$(shell git rev-list --count HEAD 2>/dev/null)/$(shell git rev-parse --short=8 HEAD 2>/dev/null)
OWNER           ?= $(shell whoami)

#SEDCMD		?= $(shell sed -e "/^:global CommitId/c :global CommitId \"${COMMITID:-unknown}\";")/$(shell sed )

#all: $(WorkFiles)

.PHONY: gakke
# checksums
#$(WorkFiles)

all: gakke
# checksums

gakke: test.txt

crakke:
		for f in $(RSC); do \
		echo "file: $$f"; > $@ \
		done

#		SUM=$$(md5sum $$f | cut -d' ' -f 1); \
#		echo "CHECKSUM: $$SUM"; \
#		done

test.txt: $1
		for f in $(ALL_RSC); do \
		SUM=$$(md5sum $$f | \
		sed -e "s| \./||" -e 's|.rsc$||' | \
		jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add');
		done

checksums: checksums.json

checksums.json: bin/checksums.sh $(ALL_RSC)
				bin/checksums.sh > html/$@

#rsc: %.rsc $(ALL_RSC)

#%.rsc: $1.rsc checksums.json
		echo $1 > $@

fake:
		for f in $1; do \
		SUM=$$(md5sum $$f | cut -d' ' -f 1); \
		echo $$f $$SUM; $2 \
		done;

#rsc $(ALL_RSC)

#%.rsc 
#		@echo > $@

#checksums.json : ALL_RSC := $(wildcard *.rsc */*.rsc)
#AM-GlobalFunc.rsc : COMMITID	:= $(VERSION)
#AM-GlobalFunc.rsc : COMMITINFO	:= "$(DATE) - Commit owner: $(OWNER)"

#ifeq ($@,AM-GlobalFunc.rsc)
#define sed-cmd =
#    	cd $(WORK_DIR) && \
#    	sed \
#		-e "/^:global CommitId/c :global CommitId \"${COMMITID:-unknown}\";" \
#		-e "/^:global CommitInfo/c :global CommitInfo \"${COMMITINFO:-unknown}\";" \
#		< "./html/${1}"
#	endef
#endif
#ifeq ($@,checksums.json)
#	define get-sums =
#    	cd $(WORK_DIR)/html && \
#    	md5sum $(find -name '*.rsc' | sort) | \
#    	sed -e "s| \./||" -e 's|.rsc$||' | \
#    	jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add' > $@
#	endef
#endif

#$(WorkFiles):
#ifeq ($@,checksums.json)
#	$(get-sums) $(ALL_RSC); > $@
#endif

#$(FuncFile): ./html/$@
#	$(sed-cmd) $< > $<~
#	mv $<~ $<

#$(WORK_DIR)/html/AM-GlobalFunc.rsc
#	cd $(WORK_DIR)/html && $(WORK_DIR)/bin/commitinfo.sh $< > $<~
#	mv $<~ $<

#commitinfo: push
#	$(WORK_DIR)/bin/$@.sh
#clean

#checkout: git checkout HEAD .

#push: 
#	git $@ origin

#ifeq (git,$(firstword $(MAKECMDGOALS)))
#    # Remaining arguments form the commit string
#    GIT_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
#    # ...and turn them into do-nothing targets
#    $(eval $(GIT_ARGS):;@:)
#endif

# git function to push to repo
#git:
#    git add . && git commit -m "$(GIT_ARGS)" && git push


#clean:
#	rm -f $(HTML) checksums.json
#	make -C tmpl/ clean

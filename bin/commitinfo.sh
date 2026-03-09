#!/bin/sh

cd ${BUILD_DIR} && \
 sed \
	-e "/^:global CommitId/c :global CommitId \"${COMMIT_ID:-unknown}\";" \
	-e "/^:global CommitTAG/c :global CommitTAG \"${COMM_TAG:-unknown}\";" \
	-e "/^:global CommitInfo/c :global CommitInfo \"${COMM_INFO:-unknown}\";" \
	< "${1}"

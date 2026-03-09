#!/usr/bin/env bash

cd "${REPO_DIR:-.}"

dirty="$(git status --porcelain || true)"
diff="$(git diff --quiet && git diff --cached --quiet || true)"
lsfiles="$(git ls-files --others --exclude-standard || true)"

if [[ -n "$diff" && -z "$lsfiles" ]]; then
    echo "[check] repo diff, go to proclean check."
    if [[ -n "$dirty" ]]; then
        echo "[check] repo dirty, stop"
        bash scripts/notify_telegram.sh "STOP: repo dirty in $(pwd)"
        exit 1
    else
        echo "[check] repo clean"
    fi
else
    echo "[check] not clean. Go to autocommit him."
    if [[ -z "$lsfiles" ]]; then
        echo "[check] Git add..."
        git add .
        git commit -m "${COMM_INFO}"
    else
        echo "[check] Git -v branch..."
        git -v brnch
        git commit -am "${COMM_INFO}"
    fi
    git push
fi

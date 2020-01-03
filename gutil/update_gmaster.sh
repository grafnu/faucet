#!/bin/bash -e

TMP_SH=/tmp/update_gmaster.sh
BASE=`git rev-parse --show-toplevel`
BASE_SH=$BASE/update_gmaster.sh
VTEMP=/tmp/GVERSION
date > $VTEMP
UPSTREAM=`git rev-parse --abbrev-ref gupdater@{upstream}`
REPO=${UPSTREAM%/*}
BASELINE=gmaster
FFILE=/tmp/FEATURES
cp $BASE/gutil/FEATURES $FFILE

name_line=`fgrep name= $BASE/setup.py`
name_line=${name_line#*\"}
PROJ=${name_line%\"*}
echo Mined project $PROJ from setup.py
VFILE=$BASE/$PROJ/GVERSION

if [ $0 != $TMP_SH ]; then
    echo Running out of $TMP_SH to mask local churn...
    cp $0 $TMP_SH
    $TMP_SH $*; false
fi

if [ "$1" == reset ]; then
    echo Reset to using master as baseline...
    BASELINE=master
fi

if [ "$1" == reset ]; then
    BASELINE=master
fi

branch=`git rev-parse --abbrev-ref HEAD`
if [ "$branch" != "gupdater" ]; then
    echo $0 should be run from the gupdater branch, not $branch.
    false
fi

files=`git status --porcelain`
if [ -n "$files" ]; then
    echo Local changes detected:
    echo $files
    echo Please resolve before updating.
    false
fi

ORIGIN=`git remote -v | egrep ^$REPO | fgrep fetch | awk '{print $2}'`
echo upstream $ORIGIN >> $VTEMP

echo Fetching remote repo...
git fetch $REPO

LOCAL=`git rev-parse gupdater`
echo gupdater $LOCAL >> $VTEMP
REMOTE=`git rev-parse $REPO/gupdater`
if [ "$LOCAL" != "$REMOTE" ]; then
    echo gupdater out of sync with upstream $REPO/gupdater
    false
fi

echo Switching to gmaster branch...
git checkout gmaster

echo Creating clean base from origin/$BASELINE...
git reset --hard origin/$BASELINE
echo $BASELINE `git rev-parse HEAD`>> $VTEMP

echo Merging feature targets...
cat $FFILE | while read hash target; do
    bhash=`git rev-list -n 1 $target`
    if [ "$bhash" != "$hash" ]; then
        echo Update hash mismatch for $target
        echo Expected $hash != found $bhash
        echo Either use a tagged target or update hash.
        false
    fi
    echo Merging $hash from $target
    git merge --no-edit $hash
    echo $hash $target >> $VTEMP
done

echo gmaster `git rev-parse HEAD` >> $VTEMP
cp $VTEMP $VFILE
git add $VFILE
git commit -m "Version assembled $(date)"

echo Done with clean gmaster merge.
echo Now time to validate and push!

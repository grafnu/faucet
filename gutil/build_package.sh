#!/bin/bash

VERSION=$(git describe)
if [[ ! $VERSION =~ ^([0-9]{1,}\.){3}[0-9]{1,}$ ]]; then
  echo Version \"$VERSION\" is invalid
  exit 1
fi
echo "Using version $VERSION"

PBR_VERSION=$VERSION python3 setup.py sdist bdist_wheel

if [ ! -f "dist/faucet-$VERSION.tar.gz" ]; then
  echo Packaged could not be created
  exit 1
fi

echo Created package dist/faucet-$VERSION.tar.gz
exit 0

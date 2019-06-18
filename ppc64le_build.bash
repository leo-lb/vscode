#!/bin/bash

echo "VSCode needs few dependencies to compile, make sure you install those if anything fails."
echo "See https://github.com/Microsoft/vscode/wiki/How-to-Contribute#prerequisites"

set -eux

VERSION=v10.16.0
DISTRO=linux-ppc64le

wget "https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz"
tar -xJvf node-$VERSION-$DISTRO.tar.xz
PATH=$(pwd)/node-$VERSION-$DISTRO/bin:$PATH

sudo npm install -g yarn gulp electron-rebuild

yarn install
yarn compile
electron-rebuild -v 4.2.4
#!/bin/bash

if [[ "$ELECTRON_BUILD_DIR" == "" ]]; then
  echo "#############################"
  echo "#############################"
  echo "ELECTRON_BUILD_DIR environment variable not provided, downloading prebuilt electron.."
	echo "The prebuilt electron binary is NOT static linked, so make sure to install it's dependencies."
	echo "For Ubuntu Bionic, the build dependencies are: build-essential clang git vim cmake python libcups2-dev pkg-config libnss3-dev libssl-dev libglib2.0-dev libgnome-keyring-dev libpango1.0-dev libdbus-1-dev libatk1.0-dev libatk-bridge2.0-dev libgtk-3-dev libkrb5-dev libpulse-dev libxss-dev re2c subversion curl libasound2-dev libpci-dev mesa-common-dev gperf bison uuid-dev clang-format libatspi2.0-dev libnotify-dev libgconf2-dev libcap-dev libxtst-dev libxss1 python-dbusmock openjdk-8-jre ninja-build clang-format"
  echo "#############################"
  echo "#############################"
	echo

  VERSION="4.2.4"
	PLATFORM="linux-ppc64"

	wget "https://github.com/leo-lb/electron/releases/download/v$VERSION/electron-v$VERSION-$PLATFORM.zip"
	mkdir -p electron-build
	cd electron-build
	unzip ../electron-v$VERSION-$PLATFORM.zip
	cd ../

	ELECTRON_BUILD_DIR=$(pwd)/electron-build
fi

$ELECTRON_BUILD_DIR/electron .

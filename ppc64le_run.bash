#!/bin/bash

if [[ "$ELECTRON_BUILD_DIR" == "" ]]; then
  echo "#############################"
  echo "#############################"
  echo "ELECTRON_BUILD_DIR environment variable not provided, downloading prebuilt electron.."
	echo "The prebuilt electron binary is NOT static linked, so make sure to install it's dependencies."
	echo "For Ubuntu Bionic, the build dependencies are: build-essential clang git vim cmake python libcups2-dev pkg-config libnss3-dev libssl-dev libglib2.0-dev libgnome-keyring-dev libpango1.0-dev libdbus-1-dev libatk1.0-dev libatk-bridge2.0-dev libgtk-3-dev libkrb5-dev libpulse-dev libxss-dev re2c subversion curl libasound2-dev libpci-dev mesa-common-dev gperf bison uuid-dev clang-format libatspi2.0-dev libnotify-dev libgconf2-dev libcap-dev libxtst-dev libxss1 python-dbusmock openjdk-8-jre ninja-build clang-format"
  echo
  echo  "You should not need to install the build dependencies, but just the shared libraries counterparts, but usually the build dependencies depend on their shared library counterpart, so it will install them too. If you don't want to install the build dependencies, figure out their shared libraries counterparts."
  echo
  echo "If you want to build Electron yourself, vscode needs the version 4.2.4, you can look at https://github.com/leo-lb/electron/blob/electron-ppc64le-4.2.4/README.md for instructions."
  echo "You can then rerun this script with ELECTRON_BUILD_DIR defined. e.g ELECTRON_BUILD_DIR=/path/to/electron-build-script-working-dir/electron-gn/src/out/Release ./ppc64le_run.bash"
  echo "#############################"
  echo "#############################"
	echo

  VERSION="6.1.7"
	PLATFORM="linux-ppc64"

	if ! [[ -f "electron-v$VERSION-$PLATFORM.zip" ]]; then
    wget "https://github.com/leo-lb/electron/releases/download/v$VERSION/electron-v$VERSION-$PLATFORM.zip"
  fi

  mkdir -p electron-build
	cd electron-build
	! [ -f ./electron ] && unzip ../electron-v$VERSION-$PLATFORM.zip
	cd ../

	ELECTRON_BUILD_DIR=$(pwd)/electron-build
fi

$ELECTRON_BUILD_DIR/electron .

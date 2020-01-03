# Copyright 2019 Colin Samples
#
# SPDX-License-Identifier: MIT
#

.DEFAULT_GOAL := all

node_version := v12.4.0
node_distro := linux-ppc64le
node_name := node-$(node_version)-$(node_distro)
node_url := https://nodejs.org/dist/$(node_version)/$(node_name).tar.xz

electron_version := 6.1.7
electron_platform := linux-ppc64
electron_name := electron-v$(electron_version)-$(electron_platform)
electron_url := https://github.com/leo-lb/electron/releases/download/v$(electron_version)/$(electron_name).zip

# The distro id gets updated by MS about every day. We use this to know if we
# should rebuild if upstream changes
vsc_dist := $(shell grep '"distro":' package.json | cut -d '"' -f 4)

objdir := .build

node_dir := $(objdir)/$(node_name)
node_bin_dir := $(node_dir)/bin

electron := $(objdir)/electron
npm := $(node_bin_dir)/npm
gulp := $(node_bin_dir)/gulp
yarn := $(node_bin_dir)/yarn
electron-rebuild := $(node_bin_dir)/electron-rebuild

electron-archive := $(objdir)/$(electron_name).zip
node-archive := $(objdir)/$(node_name).tar.xz
prereqs := $(objdir)/prereqs-installed-$(vsc_dist)
rebuilt-electron := $(objdir)/electron-rebuilt-$(electron_version)
minify-vscode := $(objdir)/minify-vscode-$(vsc_dist)
compile-vscode := $(objdir)/compile-vscode-$(vsc_dist)
rpm-build := $(objdir)/linux/rpm/ppc64le/rpm-built-$(vsc_dist)
deb-build := $(objdir)/linux/deb/ppc64el/deb/deb-built-$(vsc_dist)

export PATH := $(CURDIR)/$(node_bin_dir):$(PATH)
# Fix V8 heap size for extension bundling
export NODE_OPTIONS := --max-old-space-size=8092
export npm_config_scripts_prepend_node_path := true
export npm_config_prefix := $(CURDIR)/$(node_dir)

$(objdir):
	mkdir -p $@

$(electron-archive): | $(objdir)
	wget -O $@ $(electron_url)

$(node-archive): | $(objdir)
	wget -O $@ $(node_url)

$(electron): | $(electron-archive)
	unzip $(electron-archive) -d $(objdir)

$(npm): | $(node-archive)
	tar -xJf $(node-archive) -C $(objdir)

$(gulp) $(yarn) $(electron-rebuild): | $(npm)
	$(npm) install -g $(@F)

$(prereqs): $(yarn)
	$(yarn) install
	touch $@

$(rebuilt-electron): $(prereqs) $(electron-rebuild)
	$(electron-rebuild) -v $(electron_version)
	touch $@

$(compile-vscode): $(prereqs) $(gulp) | $(electron)
	$(gulp) compile
	touch $@

$(minify-vscode): $(rebuilt-electron) $(gulp) | $(electron)
	$(gulp) vscode-linux-ppc64-min
	touch $@

$(rpm-build): $(minify-vscode)
	$(gulp) vscode-linux-ppc64-build-rpm
	ls -1t $(dir $@)*.rpm | head -n1 > $@

$(deb-build): $(minify-vscode)
	$(gulp) vscode-linux-ppc64-build-deb
	ls -1t $(dir $@)*.deb | head -n1 > $@

.PHONY: build
build: $(compile-vscode)

.PHONY: rpm
rpm: $(rpm-build)
	$(info RPM package outputted to: $(shell cat $(rpm-build)))

.PHONY: deb
deb: $(deb-build)
	$(info DEB package outputted to: $(shell cat $(deb-build)))

.PHONY: packaging
packaging: rpm deb

.PHONY: run
run: $(compile-vscode)
	scripts/code.sh &

.PHONY: install all
ifneq ($(realpath /etc/redhat-release),)
all: rpm
install: rpm
	dnf install ./$(shell cat $(rpm-build))
else ifneq ($(realpath /etc/debian_version),)
all: deb
install: deb
	apt-get install ./$(shell cat $(deb-build))
else
all: packaging
install:
	$(error Install target only available on Red Hat or Debian based systems)
endif

.PHONY: clean
clean:
	rm -rf $(objdir)
	rm -rf out
	rm -rf out-*

.PHONY: distclean
distclean: clean
	find . \! -path "*linksTestFixtures*" -name node_modules -type d -prune -print0 | xargs -0 rm -rf
	rm -rf extensions/**/dist/
	rm -f yarn-error.log


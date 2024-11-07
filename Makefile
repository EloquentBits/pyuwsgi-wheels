MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# Figure out what version we're building
VERSION := $(shell bin/package-version)
HASH := $(shell git -C uwsgi rev-parse HEAD)

# Grab a clean checkout of uWSGI
build/$(HASH).tar.gz:
	mkdir -p build
	cd build && curl -sLO https://github.com/unbit/uwsgi/archive/$(HASH).tar.gz

# Patch Python packaging of uWSGI
build/pyuwsgi-$(VERSION): build/$(HASH).tar.gz
	cd build; tar xzf $(HASH).tar.gz
	mv build/uwsgi-$(HASH) build/pyuwsgi-$(VERSION)
	bin/patch-uwsgi-packaging build/pyuwsgi-$(VERSION)
	cp pikesquares.ini build/pyuwsgi-${VERSION}/buildconf
	echo "graft ." > build/pyuwsgi-$(VERSION)/MANIFEST.in

# Create sdist from patched uWSGI
dist/pyuwsgi-$(VERSION).tar.gz: build/pyuwsgi-$(VERSION)
	mkdir -p dist
	cd build/pyuwsgi-$(VERSION); python3 setup.py sdist
	mv build/pyuwsgi-$(VERSION)/dist/pyuwsgi-$(VERSION).tar.gz $@

.PHONY: sdist
sdist: dist/pyuwsgi-$(VERSION).tar.gz

.PHONY: update
update:
	cd uwsgi; git pull

.PHONY: clean
clean:
	rm -rf ./dist ./build


## the publicly-visible name of your binary
NAME=mysql-remote-diag

## the go-get'able path
PKG_PATH=github.com/bluestatedigital/$(NAME)

## version, taken from Git tag (like v1.0.0) or hash
VER:=$(shell (git describe --always --dirty 2>/dev/null || echo "¯\\\\\_\\(ツ\\)_/¯") | sed -e 's/^v//g' )

## fully-qualified path to this Makefile
MKFILE_PATH := $(realpath $(lastword $(MAKEFILE_LIST)))
## fully-qualified path to the current directory
CURRENT_DIR := $(patsubst %/,%,$(dir $(MKFILE_PATH)))

BIN=.godeps/bin
GPM=$(BIN)/gpm
GPM_LINK=$(BIN)/gpm-link
GVP=$(BIN)/gvp

## @todo should use "$(GVP) in", but that fails
## all non-test source files
SOURCES:=$(shell go list -f '{{range .GoFiles}}{{ $$.Dir }}/{{.}} {{end}}' ./... | sed -e 's@$(CURRENT_DIR)/@@g' )

.PHONY: all deps build clean rpm

## targets after a | are order-only; the presence of the target is sufficient
## http://stackoverflow.com/questions/4248300/in-a-makefile-is-a-directory-name-a-phony-target-or-real-target

all: build

$(BIN) stage:
	mkdir -p $@

$(GPM): | $(BIN)
	curl -s -L -o $@ https://github.com/pote/gpm/raw/v1.3.2/bin/gpm
	chmod +x $@

$(GPM_LINK): | $(BIN)
	curl -s -L -o $@ https://github.com/elcuervo/gpm-link/raw/v0.0.1/bin/gpm-link
	chmod +x $@

$(GVP): | $(BIN)
	curl -s -L -o $@ https://github.com/pote/gvp/raw/v0.1.0/bin/gvp
	chmod +x $@

.godeps/.gpm_installed: $(GPM) $(GVP) $(GPM_LINK) Godeps
	test -e .godeps/src/$(PKG_PATH) || $(GVP) in $(GPM) link add $(PKG_PATH) $(CURRENT_DIR)
	$(GVP) in $(GPM) install
	touch $@

## just installs dependencies
deps: .godeps/.gpm_installed

## build the binary
## augh!  gvp shell escaping!!
## https://github.com/pote/gvp/issues/22
stage/$(NAME): .godeps/.gpm_installed $(SOURCES) | stage
	$(GVP) in go build -o $@ -ldflags '-X\ main.version=$(VER)' -v .

stage/$(NAME)-linux: .godeps/.gpm_installed $(SOURCES) | stage
	$(GVP) in GOOS=linux GOARCH=amd64 go build -o $@ -ldflags '-X\ main.version=$(VER)' -v .

stage/$(NAME)-windows: .godeps/.gpm_installed $(SOURCES) | stage
	$(GVP) in GOOS=windows GOARCH=386 go build -o $@ -ldflags '-X\ main.version=$(VER)' -v .

build: \
	stage/$(NAME) \
	stage/$(NAME)-linux \
	stage/$(NAME)-windows

## duh
clean:
	rm -rf stage .godeps release

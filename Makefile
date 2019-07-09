export GIT_SHA1          := $(shell git rev-parse --short HEAD)
export DOCKER_IMAGE_NAME := icingaweb2
export DOCKER_NAME_SPACE := ${USER}
export DOCKER_VERSION    ?= latest
export BUILD_DATE        := $(shell date +%Y-%m-%d)
export BUILD_VERSION     := $(shell date +%y%m)
export BUILD_TYPE        ?= stable
export ICINGAWEB_VERSION ?= 2.6.3
export INSTALL_THEMES    ?= true
export INSTALL_MODULES   ?= true


.PHONY: build shell run exec start stop clean compose-file github-cache

default: build

github-cache:
	@hooks/github-cache

offline_themes:
	@hooks/offline_themes

offline_modules:
	@hooks/offline_modules

build:	offline_themes	offline_modules
	@hooks/build

shell:
	@hooks/shell

run:
	@hooks/run

exec:
	@hooks/exec

start:
	@hooks/start

stop:
	@hooks/stop

clean:
	@hooks/clean

compose-file:
	@hooks/compose-file

linter:
	@tests/linter.sh

integration_test:
	@tests/integration_test.sh

test: linter integration_test

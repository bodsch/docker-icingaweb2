
include env_make

NS       = bodsch
VERSION ?= latest

REPO     = docker-icingaweb2
NAME     = icingaweb2
INSTANCE = default

BUILD_DATE := $(shell date +%Y-%m-%d)
BUILD_VERSION := $(shell date +%y%m)
ICINGAWEB_VERSION ?= 2.4.2
INSTALL_THEMES ?= 'true'
INSTALL_MODULES ?= 'true'

.PHONY: build push shell run start stop rm release

build:
	docker build \
		--force-rm \
		--compress \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg ICINGAWEB_VERSION=${ICINGAWEB_VERSION} \
		--build-arg INSTALL_THEMES=$(INSTALL_THEMES) \
		--build-arg INSTALL_MODULES=${INSTALL_MODULES} \
		--tag $(NS)/$(REPO):${ICINGAWEB_VERSION} .

clean:
	docker rmi \
		--force \
		$(NS)/$(REPO):${ICINGAWEB_VERSION}

history:
	docker history \
		$(NS)/$(REPO):${ICINGAWEB_VERSION}

push:
	docker push \
		$(NS)/$(REPO):${ICINGAWEB_VERSION}

shell:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		--interactive \
		--tty \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${ICINGAWEB_VERSION} \
		/bin/sh

run:
	docker run \
		--rm \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${ICINGAWEB_VERSION}

exec:
	docker exec \
		--interactive \
		--tty \
		$(NAME)-$(INSTANCE) \
		/bin/sh

start:
	docker run \
		--detach \
		--name $(NAME)-$(INSTANCE) \
		$(PORTS) \
		$(VOLUMES) \
		$(ENV) \
		$(NS)/$(REPO):${ICINGAWEB_VERSION}

stop:
	docker stop \
		$(NAME)-$(INSTANCE)

rm:
	docker rm \
		$(NAME)-$(INSTANCE)

release: build
	make push -e VERSION=${ICINGAWEB_VERSION}

default: build




CONTAINER  := icingaweb2
IMAGE_NAME := docker-icingaweb2

DATA_DIR   := /tmp/docker-data

build:
	docker \
		build \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--build-arg VCS_REF=${GIT_SHA1} \
		--build-arg ICINGAWEB_VERSION="2.4.1" \
		--rm --tag=$(IMAGE_NAME) .
	@echo Image tag: ${IMAGE_NAME}

clean:
	docker \
		rmi ${IMAGE_NAME}

run:
	docker \
		run \
		--detach \
		--interactive \
		--tty \
		--publish=5665:5665 \
		--publish=6666:6666 \
		--volume=${DATA_DIR}:/srv \
		--hostname=${CONTAINER} \
		--name=${CONTAINER} \
		$(IMAGE_NAME)

shell:
	docker \
		run \
		--rm \
		--interactive \
		--tty \
		--publish=5665:5665 \
		--publish=6666:6666 \
		--volume=${DATA_DIR}:/srv \
		--hostname=${CONTAINER} \
		--name=${CONTAINER} \
		$(IMAGE_NAME) \
		/bin/sh

exec:
	docker \
		exec \
		--interactive \
		--tty \
		${CONTAINER} \
		/bin/sh

stop:
	docker \
		kill ${CONTAINER}

history:
	docker \
		history ${IMAGE_NAME}


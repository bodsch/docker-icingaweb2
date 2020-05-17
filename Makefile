default: image

docker-image = registry.gitlab.com/olemisea/icingaweb2

image:
	docker build \
		--squash \
		-t $(docker-image):dev \
		.

enter: image
	docker run -ti --entrypoint bash $(docker-image):dev

run: image
	docker run -ti $(docker-image):dev

show-images:
	docker images | grep "$(docker-image)"

clear:
	rm -rf ./build

# Remove dangling images
clean-images:
	docker images -a -q \
		--filter "reference=$(docker-image)" \
		--filter "dangling=true" \
	| xargs docker rmi

# Remove all images
clear-images:
	docker images -a -q \
		--filter "reference=$(docker-image)" \
	| xargs docker rmi

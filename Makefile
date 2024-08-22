BASE_IMAGE:=dbeaver/cloudbeaver
BASE_IMAGE_TAG:=24.1
BUILD_DATE:= `date -u +"%Y-%m-%dT%H:%M:%SZ"`

CONTAINER_PORT:=8978
HOST_PORT:=8978

APP_NAME:=cloudbeaver

IMAGE_REPO=containers.renci.org/helxplatform
VERSION=helx-dev


build: ## Build the image.
	    docker build --pull \
		--build-arg BUILD_IMAGE=${VERSION} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--tag ${IMAGE_REPO}/${APP_NAME}:${VERSION} \
		--tag ${VERSION} \
		.

build-nc: ## Build the image without caching.
	    docker build --pull --no-cache \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG} \
		-t ${APP_NAME} .

docker-clean: ## Prune unused images, containers, and networks from the local Docker system.
	docker system prune -f
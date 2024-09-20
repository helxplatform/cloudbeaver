BASE_IMAGE:=dbeaver/cloudbeaver
BASE_IMAGE_TAG:=24.1
BUILD_DATE:= `date -u +"%Y-%m-%dT%H:%M:%SZ"`

CONTAINER_PORT:=8978
HOST_PORT:=8978

APP_NAME:=cloudbeaver

IMAGE_REPO=containers.renci.org/helxplatform/third-party
VERSION=0.0.2


build: ## Build the image.
	docker build --pull --no-cache \
		--build-arg BUILD_IMAGE=${VERSION} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--tag ${IMAGE_REPO}/${APP_NAME}:${VERSION} \
		--tag ${APP_NAME}:${VERSION} \
		.

build-nc: ## Build the image without caching.
	    docker build --no-cache \
		--build-arg BUILD_IMAGE=${VERSION} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--tag ${IMAGE_REPO}/${APP_NAME}:${VERSION} \
		--tag ${VERSION} \
		.

docker-clean: ## Prune unused images, containers, and networks from the local Docker system.
	docker system prune -f

push:
	docker push ${IMAGE_REPO}/${APP_NAME}:${VERSION}

run:
	docker run --name cloudbeaver2 \
		--rm -ti -p 8080:8978 \
		${APP_NAME}:${VERSION}

#-v /opt/cloudbeaver/workspace 
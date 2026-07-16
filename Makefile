BASE_IMAGE:=dbeaver/cloudbeaver
BASE_IMAGE_TAG:=24.1
BUILD_DATE:= `date -u +"%Y-%m-%dT%H:%M:%SZ"`

CONTAINER_PORT:=8978
HOST_PORT:=8978

APP_NAME:=cloudbeaver

IMAGE_REPO=containers.renci.org/helxplatform/third-party
VERSION=1.0.1


build: ## Build the image.
	docker build --pull --no-cache \
	  --platform linux/amd64 \
		--build-arg BUILD_IMAGE=${VERSION} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--tag ${IMAGE_REPO}/${APP_NAME}:${VERSION} \
		--tag joshuaseals/${APP_NAME}:${VERSION} \
		--tag ${APP_NAME}:${VERSION} \
		.

build-local: ## Build the image for mac.
	docker build --pull --no-cache \
		--build-arg BUILD_IMAGE=${VERSION} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--tag ${APP_NAME}:${VERSION} \
		.

docker-clean: ## Prune unused images, containers, and networks from the local Docker system.
	docker system prune -f

personal-push:
	docker push joshuaseals/${APP_NAME}:${VERSION}

push:
	docker push ${IMAGE_REPO}/${APP_NAME}:${VERSION}

run:
	docker run --name cloudbeaver2 \
		--rm -ti -p 8080:8978 \
		${APP_NAME}:${VERSION}

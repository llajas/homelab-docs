# --------- configurable bits ----------
REGISTRY ?= registry.lajas.tech
REPO     ?= homelab-documenatation
TAG      := $(shell git describe --tags --always)
REPO_URL ?= https://github.com/llajas/homelab

# --------- derived names --------------
IMG_SHA  := $(REGISTRY)/$(REPO):$(TAG)     # e.g. registry.lajas.tech/vscode-tunnel:7dd16fc
IMG_LATEST := $(REGISTRY)/$(REPO):latest

# fall back to Dockerfile if no Containerfile
ifeq ($(wildcard Containerfile),)
  BUILD_FILE := Dockerfile
else
  BUILD_FILE := Containerfile
endif

# --------------------------------------
.PHONY: all build push run dev

all: build push

build:
	# build once, stamp it with both tags in a single command
	docker build \
	  -f $(BUILD_FILE) \
	  -t $(IMG_SHA) \
	  -t $(IMG_LATEST) \
	  --build-arg REPO_URL=$(REPO_URL) .

push:
	# push the Git-specific tag
	docker push $(IMG_SHA)
	# push the floating 'latest' tag
	docker push $(IMG_LATEST)

# Run locally with docker-compose
run:
	docker-compose up -d

# Run locally in development mode (with logs)
dev:
	docker-compose up

# Stop and clean up
stop:
	docker-compose down

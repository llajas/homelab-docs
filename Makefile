# --------- configurable bits ----------
REGISTRY ?= registry.lajas.tech
REPO     ?= homelab-documentation
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
.PHONY: all build push run dev stop helm-install helm-upgrade helm-uninstall helm-template

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

# Helm commands for Kubernetes deployment
helm-install:
	helm install homelab-docs ./helm/homelab-docs \
	  --set image.repository=$(REGISTRY)/$(REPO) \
	  --set image.tag=$(TAG) \
	  --set config.repoUrl=$(REPO_URL)

helm-upgrade:
	helm upgrade homelab-docs ./helm/homelab-docs \
	  --set image.repository=$(REGISTRY)/$(REPO) \
	  --set image.tag=$(TAG) \
	  --set config.repoUrl=$(REPO_URL)

helm-uninstall:
	helm uninstall homelab-docs

helm-template:
	helm template homelab-docs ./helm/homelab-docs \
	  --set image.repository=$(REGISTRY)/$(REPO) \
	  --set image.tag=$(TAG) \
	  --set config.repoUrl=$(REPO_URL)

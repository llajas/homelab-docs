# homelab-docs

A simple Docker compose manifest that hosts the documentation for [llajas/homelab](https://github.com/llajas/homelab).

### Why?

The [llajas/homelab](https://github.com/llajas/homelab) repo comes bundled with:
1. The documentation for the lab itself.
2. The ability to host the docs via the `make docs` command - This creates a container that hosts the documentation on port `8000` and is accessible via `HTTP/S` but can only be initiated after cloning [llajas/homelab](https://github.com/llajas/homelab) and running the `make tools` command, else installing all required dependencies needed, which are included in this manifest.

Upon creation, the container grabs and runs the `squidfunk/mkdocs-material` image and will watch the paths for changes to either the 'docs' folder or the 'mkdocs.yml' definition file and serve them accordingly.

While this is great and serves the immediate purpose, there are two concerns:
1. The documentation will only update if I remember to log onto the controller occasionally and perform a `git pull`.
2. In the event I need to rebuild the cluster (or a local outage), I want a way to host the documentation outside of the homelab itself and related infrastructure for higher availability.

This aims to solve both of those problems by defining two services:
1. An `nginx` service that uses the `nginx:latest` Docker image and exposes port 80 on the container as port 5000 on the host machine. It also mounts a volume at the `/usr/share/nginx/html` path in the container, which is named `static` in the configuration and also shared with...
2. A `build` service that uses the `alpine:latest` Docker image and installs `Git`, `Python 3`, and `pip` (the Python package manager) using `apk` among other packages. It then proceeds to clone the [llajas/homelab](https://github.com/llajas/homelab) Github repository, creates the documentation via `mkdocs` which is then copied into the shared volume that is read by `nginx`. The container then watches for any further commits/changes to the documentation via GitHub (once every 2 minutes). Upon detection of a new commit, the image pulls the latest copy from the repo and rebuilds the documentation, serving to `nginx` once again.


### Why not use 'Github Pages?'
I likeley could have/may do this, but I wanted to build this container as a test to myself and needed a way to package it away from my immediate cluster setup. I'll likely change this over to GitHub Pages over time, but this fits my needs, for now.

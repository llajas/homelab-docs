# **homelab-docs**

A simple Docker Compose manifest that hosts the documentation for [llajas/homelab](https://github.com/llajas/homelab).

## **Why?**

The [llajas/homelab](https://github.com/llajas/homelab) repository includes:
1. The documentation for the lab itself.
2. The ability to host the documentation via the `make docs` command.  
   - This starts the `mkdocs` service that hosts the documentation on port `8000` over `HTTP/S` on the local machine.
   - However, this requires cloning the [llajas/homelab](https://github.com/llajas/homelab) repo and running `make tools` first, or manually installing all dependencies.

This container simplifies that process by automating deployment and continuous updates.

## **How It Works**

Instead of relying on the default `squidfunk/mkdocs-material` image, this setup:
- Uses a **single-container approach** based on `nginx:alpine` to both build and serve the documentation.
- Runs a background loop that:
  1. Clones the latest `homelab` documentation from GitHub.
  2. Builds the site using `mkdocs-material`.
  3. Serves it through `nginx`.
  4. Watches for updates every **2 minutes**, rebuilding and redeploying changes automatically.

### **Key Benefits**
- **Always Up to Date:** No need to manually `git pull`—the container handles updates automatically.
- **Single-Container Simplicity:** No need for a separate builder and web server. The container manages both (Compose file is included if you prefer this approach).
- **Decoupled from the Homelab:** The docs can be hosted externally, ensuring availability even if the homelab is down.

## **Container Setup**
This setup consists of two services:

### **1. Documentation Server (nginx)**
- Uses `nginx:alpine` to serve the built documentation.
- Hosts content at `/usr/share/nginx/html`.
- Exposes port `80` on the container.

### **2. Documentation Builder**
- Uses `python3` and `pip` inside a virtual environment to install `mkdocs-material`.
- Clones the latest documentation from GitHub.
- Builds the site using `mkdocs build`.
- Copies the generated site to the `nginx` directory.
- Runs a loop that checks for updates **every 30 seconds** and rebuilds the site if changes are detected.

## **Why Not Use GitHub Pages?**
I could (and might) switch to GitHub Pages later. However, this project serves as a self-hosted alternative and a personal learning exercise. It allows me to test deployment strategies outside of my main Kubernetes cluster while keeping the documentation available and portable.

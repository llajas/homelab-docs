# Use the nginx:alpine base image
FROM nginx:alpine

# Install dependencies
RUN apk add --no-cache git python3 py3-pip py3-virtualenv

# Create a virtual environment and install mkdocs-material
RUN python3 -m venv /venv && \
    . /venv/bin/activate && \
    pip install --no-cache-dir mkdocs-material

# Set the working directory to /usr/local/src
WORKDIR /usr/local/src

# Set environment variable to use virtualenv
ENV PATH="/venv/bin:$PATH"

# Start nginx in the background and run mkdocs loop
CMD nginx & while true; do \
        git clone https://github.com/llajas/homelab . \
        && mkdocs build \
        && cp -RT ./site /usr/share/nginx/html; \
        while true; do \
            git fetch origin; \
            git diff HEAD origin/master --exit-code; \
            if [ $? -eq 1 ]; then \
                git reset --hard origin/master; \
                mkdocs build; \
                cp -RT ./site /usr/share/nginx/html; \
            fi; \
            sleep 30; \
        done; \
    done

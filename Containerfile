# Use the nginx:alpine base image
FROM nginx:alpine

# Install dependencies
RUN apk add --no-cache git python3 py3-pip py3-virtualenv curl

# Create a non-root user for security
RUN addgroup -g 1001 appuser && \
    adduser -D -u 1001 -G appuser appuser

# Create a virtual environment and install mkdocs-material
RUN python3 -m venv /venv && \
    . /venv/bin/activate && \
    pip install --no-cache-dir mkdocs-material

# Set the working directory
WORKDIR /usr/local/src

# Change ownership of working directory to appuser
RUN chown -R appuser:appuser /usr/local/src /venv

# Set environment variables
ENV PATH="/venv/bin:$PATH"

# Build argument for repository URL (can be overridden at build time)
ARG REPO_URL="https://github.com/llajas/homelab"
ENV REPO_URL="${REPO_URL}"

ENV UPDATE_INTERVAL="120"
ENV NGINX_ROOT="/usr/share/nginx/html"

# Copy custom nginx configuration if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Configure nginx to log to stdout/stderr for Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Create entrypoint script
COPY <<EOF /entrypoint.sh
#!/bin/sh
set -e

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to build and deploy docs
build_and_deploy() {
    log "Starting build process..."
    
    # Clean up any existing repo
    rm -rf /tmp/repo
    mkdir -p /tmp/repo
    cd /tmp/repo
    
    # Clone repository with error handling
    if ! git clone "\${REPO_URL}" .; then
        log "ERROR: Failed to clone repository"
        return 1
    fi
    
    # Build documentation
    if ! mkdocs build; then
        log "ERROR: Failed to build documentation"
        return 1
    fi
    
    # Deploy to nginx
    if ! cp -RT ./site "\${NGINX_ROOT}"; then
        log "ERROR: Failed to deploy to nginx"
        return 1
    fi
    
    log "Build and deploy completed successfully"
    return 0
}

# Function to check for updates
check_for_updates() {
    cd /tmp/repo || return 1
    
    git fetch origin || {
        log "ERROR: Failed to fetch from origin"
        return 1
    }
    
    if ! git diff HEAD origin/master --exit-code >/dev/null 2>&1; then
        log "Updates detected, rebuilding..."
        git reset --hard origin/master || {
            log "ERROR: Failed to reset to origin/master"
            return 1
        }
        return 0  # Updates found
    fi
    
    return 1  # No updates
}

# Start nginx in background
log "Starting nginx..."
nginx -g "daemon off;" &
NGINX_PID=\$!

# Trap signals for graceful shutdown
trap 'log "Shutting down..."; kill \$NGINX_PID; exit 0' TERM INT

# Initial build
log "Performing initial build..."
if ! build_and_deploy; then
    log "FATAL: Initial build failed"
    exit 1
fi

# Main loop
log "Starting update loop (checking every \${UPDATE_INTERVAL} seconds)..."
while true; do
    sleep "\${UPDATE_INTERVAL}"
    
    if check_for_updates; then
        if ! build_and_deploy; then
            log "ERROR: Failed to rebuild after update detection"
            # Continue loop instead of exiting
        fi
    fi
done
EOF

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER appuser

# Use the entrypoint script
CMD ["/entrypoint.sh"]

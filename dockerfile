version: '3'
services:
  nginx:
    image: nginx:latest
    ports:
      - "5000:80"
    volumes:
      - static:/usr/share/nginx/html
  build:
    image: alpine:latest # TODO https://github.com/squidfunk/mkdocs-material/issues/2945
    working_dir: /usr/local/src
    command: /bin/sh -c "apk add git python3 py3-pip && pip install mkdocs-material && git clone https://github.com/llajas/homelab . && mkdocs build && cp -RT ./site /usr/share/nginx/html && while true; do git fetch origin && git diff HEAD origin/master --exit-code && if [ $$? -eq 1 ]; then git reset --hard origin/master && mkdocs build && cp -RT ./site /usr/share/nginx/html; fi; sleep 120; done"
    volumes:
      - static:/usr/share/nginx/html
    restart: always
volumes:
  static:
    driver: local

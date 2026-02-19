.PHONY: help web web-wasm clean

APP_DIR := tikiya_web
WEB_HOST ?= 0.0.0.0
WEB_PORT ?= 3000

help:
	@printf '%s\n' \
		"Targets:" \
		"  web       Build Flutter web then serve on http://$(WEB_HOST):$(WEB_PORT)/" \
		"  web-wasm  Same as web, but uses --wasm" \
		"  clean     Flutter clean"

web:
	WEB_HOST=$(WEB_HOST) WEB_PORT=$(WEB_PORT) ./scripts/serve_web_mobile.sh

web-wasm:
	WEB_HOST=$(WEB_HOST) WEB_PORT=$(WEB_PORT) WASM=1 ./scripts/serve_web_mobile.sh

clean:
	cd $(APP_DIR) && flutter clean

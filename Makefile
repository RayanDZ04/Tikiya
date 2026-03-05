SHELL := /bin/sh

DOCKER := $(shell command -v docker 2>/dev/null)
COMPOSE_CMD := $(shell command -v docker-compose 2>/dev/null)
ifeq ($(COMPOSE_CMD),)
	COMPOSE_CMD := docker compose
endif

ANDROID_SDK_CANDIDATES := \
	$(shell if [ -d "$$HOME/Android/Sdk" ]; then echo $$HOME/Android/Sdk; fi) \
	$(shell if [ -d "$$HOME/Android/sdk" ]; then echo $$HOME/Android/sdk; fi) \
	$(ANDROID_SDK_ROOT) \
	$(ANDROID_HOME) \
	$(shell if [ -d "$$HOME/.buildozer/android/platform/android-sdk" ]; then echo $$HOME/.buildozer/android/platform/android-sdk; fi)
DETECTED_ANDROID_SDK_ROOT := $(shell for d in $(ANDROID_SDK_CANDIDATES); do \
	if [ -n "$$d" ] && [ -x "$$d/emulator/emulator" ] && [ -x "$$d/platform-tools/adb" ]; then echo $$d; break; fi; \
done)
ifneq ($(DETECTED_ANDROID_SDK_ROOT),)
ANDROID_SDK_ROOT := $(DETECTED_ANDROID_SDK_ROOT)
endif
ANDROID_HOME ?= $(ANDROID_SDK_ROOT)
ADB ?= $(ANDROID_SDK_ROOT)/platform-tools/adb
FLUTTER := $(shell command -v flutter 2>/dev/null || find $$HOME/flutter/bin -name flutter 2>/dev/null | head -1)
EMULATOR ?= $(ANDROID_SDK_ROOT)/emulator/emulator
AVD_NAME ?= Pixel_7_Pro
EMULATOR_ARGS ?= -netdelay none -netspeed full -gpu auto
EMULATOR_ARGS_BLACK ?= -no-snapshot -wipe-data -gpu swiftshader_indirect -accel auto -netdelay none -netspeed full
EMULATOR_DISPLAY ?= $(DISPLAY)
EMULATOR_ENV ?= DISPLAY=$(EMULATOR_DISPLAY) XAUTHORITY=$(XAUTHORITY) QT_QPA_PLATFORM=xcb ANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) ANDROID_HOME=$(ANDROID_HOME)
EMULATOR_LOG ?= .emulator.log
ADB_WAIT_TIMEOUT ?= 180
ADB_SERIAL_CMD = $(ADB) devices | awk '/^emulator-/{print $$1; exit}'
PKG_MOBILE ?= com.tikiya
PKG_ORGA ?= com.tikiya.orga
PKG_MOBILE_OLD ?= com.example.app_mobile
PKG_ORGA_OLD ?= com.example.tikiya_orga

.PHONY: build android android_fix android_display0 android_display1 android_fix_display0 android_fix_display1 app app_orga backend_up dev_app dev_app_orga run_app run_app_orga clean app_clean web web_mobile web_orga dev dev_down dev_logs

IMAGE_MOBILE ?= tikiya-android_build_mobile:latest
IMAGE_ORGA ?= tikiya-android_build_organisateur:latest

define export_build
	@rm -rf $(2)/build; \
	 id=$$(docker create $(1)); \
	 docker cp $$id:/app/build - | tar -x -C $(2) --no-same-owner --no-same-permissions; \
	 docker rm $$id >/dev/null;
endef

# Build Android APK + AAB for both apps via Docker
build:
	@if [ -z "$(DOCKER)" ]; then echo "Docker est requis"; exit 1; fi
	$(COMPOSE_CMD) run --rm android_build_mobile
	$(COMPOSE_CMD) run --rm android_build_organisateur

# Start Android Studio emulator (local)
android:
	@if [ -z "$(ANDROID_SDK_ROOT)" ]; then \
		echo "ANDROID_SDK_ROOT introuvable"; \
		echo "Définis ANDROID_SDK_ROOT ou ANDROID_HOME (ex: $$HOME/Android/Sdk)"; \
		exit 1; \
	fi
	@if [ ! -x "$(EMULATOR)" ]; then echo "Emulator introuvable: $(EMULATOR)"; exit 1; fi
	@if [ ! -x "$(ADB)" ]; then echo "ADB introuvable: $(ADB)"; exit 1; fi
	@serial=$$($(ADB_SERIAL_CMD)); \
	 if [ -n "$$serial" ]; then echo "Emulateur déjà actif: $$serial"; exit 0; fi; \
	 echo "Lancement AVD: $(AVD_NAME)"; \
	 $(EMULATOR_ENV) $(EMULATOR) -avd $(AVD_NAME) $(EMULATOR_ARGS) > $(EMULATOR_LOG) 2>&1 & \
	 echo "Log emulateur: $(EMULATOR_LOG)"; \
	 timeout $(ADB_WAIT_TIMEOUT) sh -c "while [ -z \"$$($(ADB_SERIAL_CMD))\" ]; do sleep 2; done" \
	   || (echo "Emulateur non démarré"; tail -n 200 $(EMULATOR_LOG); exit 1); \
	 serial=$$($(ADB_SERIAL_CMD)); \
	 $(ADB) -s $$serial wait-for-device; \
	 echo "Emulateur prêt"

android_fix:
	@if [ -z "$(ANDROID_SDK_ROOT)" ]; then \
		echo "ANDROID_SDK_ROOT introuvable"; \
		echo "Définis ANDROID_SDK_ROOT ou ANDROID_HOME (ex: $$HOME/Android/Sdk)"; \
		exit 1; \
	fi
	@if [ ! -x "$(EMULATOR)" ]; then echo "Emulator introuvable: $(EMULATOR)"; exit 1; fi
	@if [ ! -x "$(ADB)" ]; then echo "ADB introuvable: $(ADB)"; exit 1; fi
	@serial=$$($(ADB_SERIAL_CMD)); \
	 if [ -n "$$serial" ]; then echo "Emulateur déjà actif: $$serial"; exit 0; fi; \
	 echo "Lancement AVD (fix écran noir): $(AVD_NAME)"; \
	 $(EMULATOR_ENV) $(EMULATOR) -avd $(AVD_NAME) $(EMULATOR_ARGS_BLACK) > $(EMULATOR_LOG) 2>&1 & \
	 echo "Log emulateur: $(EMULATOR_LOG)"; \
	 timeout $(ADB_WAIT_TIMEOUT) sh -c "while [ -z \"$$($(ADB_SERIAL_CMD))\" ]; do sleep 2; done" \
	   || (echo "Emulateur non démarré"; tail -n 200 $(EMULATOR_LOG); exit 1); \
	 serial=$$($(ADB_SERIAL_CMD)); \
	 $(ADB) -s $$serial wait-for-device; \
	 echo "Emulateur prêt"

android_display0:
	$(MAKE) android EMULATOR_DISPLAY=:0

android_display1:
	$(MAKE) android EMULATOR_DISPLAY=:1

android_fix_display0:
	$(MAKE) android_fix EMULATOR_DISPLAY=:0

android_fix_display1:
	$(MAKE) android_fix EMULATOR_DISPLAY=:1

# Build and install App_mobile APK on the running emulator
app: android
	@if [ -n "$(FLUTTER)" ]; then \
	  echo "Build local Flutter (App_mobile)..."; \
	  cd $(PWD)/App_mobile && $(FLUTTER) build apk --release; \
	else \
	  echo "Flutter introuvable en local, build via Docker..."; \
	  $(COMPOSE_CMD) run --rm android_build_mobile; \
	  find $(PWD)/App_mobile/build -user root -exec chown $(USER):$(USER) {} + 2>/dev/null || true; \
	fi
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi; \
	 for pkg in $(PKG_MOBILE) $(PKG_MOBILE_OLD); do $(ADB) -s $$serial uninstall $$pkg >/dev/null 2>&1 || true; done; \
	 $(ADB) -s $$serial install -r $(PWD)/App_mobile/build/app/outputs/flutter-apk/app-release.apk

# Build and install App_mobile_organisateur APK on the running emulator
app_orga: android
	@if [ -n "$(FLUTTER)" ]; then \
	  echo "Build local Flutter (App_mobile_organisateur)..."; \
	  cd $(PWD)/App_mobile_organisateur && $(FLUTTER) build apk --release; \
	else \
	  echo "Flutter introuvable en local, build via Docker..."; \
	  $(COMPOSE_CMD) run --rm android_build_organisateur; \
	  find $(PWD)/App_mobile_organisateur/build -user root -exec chown $(USER):$(USER) {} + 2>/dev/null || true; \
	fi
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi; \
	 for pkg in $(PKG_ORGA) $(PKG_ORGA_OLD); do $(ADB) -s $$serial uninstall $$pkg >/dev/null 2>&1 || true; done; \
	 $(ADB) -s $$serial install -r $(PWD)/App_mobile_organisateur/build/app/outputs/flutter-apk/app-release.apk

# Démarre la DB + l'API en arrière-plan (si pas déjà up)
backend_up:
	@echo "Démarrage DB + API en arrière-plan..."
	$(COMPOSE_CMD) -f docker-compose.yml -f docker-compose.dev.yml up --build -d db api
	@echo "Backend lancé (accessible sur :8080 dans quelques secondes)"

# Flutter hot-reload dev mode (App_mobile) — r=reload R=restart q=quitter
# Lance l'emulateur ET le backend en parallèle, puis flutter run
dev_app:
	@$(MAKE) android &
	@$(MAKE) backend_up &
	@wait
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi
	cd $(PWD)/App_mobile && $(FLUTTER) run --debug -d $$($(ADB_SERIAL_CMD))

# Flutter hot-reload dev mode (App_mobile_organisateur)
dev_app_orga:
	@$(MAKE) android &
	@$(MAKE) backend_up &
	@wait
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi
	cd $(PWD)/App_mobile_organisateur && $(FLUTTER) run --debug -d $$($(ADB_SERIAL_CMD))

# Lance uniquement flutter run (émulateur + backend déjà démarrés)
run_app:
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté, lance d'abord: make android"; exit 1; fi
	cd $(PWD)/App_mobile && $(FLUTTER) run --debug -d $$($(ADB_SERIAL_CMD))

# Lance uniquement flutter run organisateur (émulateur + backend déjà démarrés)
run_app_orga:
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté, lance d'abord: make android"; exit 1; fi
	cd $(PWD)/App_mobile_organisateur && $(FLUTTER) run --debug -d $$($(ADB_SERIAL_CMD))

clean:
	@serial=$$($(ADB_SERIAL_CMD)); if [ -n "$$serial" ]; then $(ADB) -s $$serial emu kill >/dev/null 2>&1 || true; fi
	- rm -rf ./App_mobile/build ./App_mobile_organisateur/build

app_clean:
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi; \
	 for pkg in $(PKG_MOBILE) $(PKG_MOBILE_OLD) $(PKG_ORGA) $(PKG_ORGA_OLD); do $(ADB) -s $$serial uninstall $$pkg >/dev/null 2>&1 || true; done

web:
	$(MAKE) -C App_web web

web_mobile:
	./scripts/serve_web_mobile.sh

web_orga:
	./scripts/serve_web_orga.sh

dev:
	$(COMPOSE_CMD) -f docker-compose.yml -f docker-compose.dev.yml up --build

dev_down:
	$(COMPOSE_CMD) -f docker-compose.yml -f docker-compose.dev.yml down -v

dev_logs:
	$(COMPOSE_CMD) -f docker-compose.yml -f docker-compose.dev.yml logs -f

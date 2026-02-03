SHELL := /bin/sh

DOCKER := $(shell command -v docker 2>/dev/null)
COMPOSE_CMD := $(shell command -v docker-compose 2>/dev/null)
ifeq ($(COMPOSE_CMD),)
	COMPOSE_CMD := docker compose
endif

ANDROID_SDK_ROOT ?= $(shell if [ -d "$$HOME/Android/Sdk" ]; then echo $$HOME/Android/Sdk; elif [ -n "$$ANDROID_SDK_ROOT" ]; then echo $$ANDROID_SDK_ROOT; elif [ -n "$$ANDROID_HOME" ]; then echo $$ANDROID_HOME; elif [ -d "$$HOME/.buildozer/android/platform/android-sdk" ]; then echo $$HOME/.buildozer/android/platform/android-sdk; fi)
ANDROID_HOME ?= $(ANDROID_SDK_ROOT)
ADB ?= $(ANDROID_SDK_ROOT)/platform-tools/adb
EMULATOR ?= $(ANDROID_SDK_ROOT)/emulator/emulator
AVD_NAME ?= Pixel_7_Pro
EMULATOR_ARGS ?= -netdelay none -netspeed full -gpu auto
EMULATOR_ENV ?= DISPLAY=$(DISPLAY) XAUTHORITY=$(XAUTHORITY) QT_QPA_PLATFORM=xcb ANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) ANDROID_HOME=$(ANDROID_HOME)
EMULATOR_LOG ?= .emulator.log
ADB_WAIT_TIMEOUT ?= 180
ADB_SERIAL_CMD = $(ADB) devices | awk '/^emulator-/{print $$1; exit}'
PKG_MOBILE ?= com.tikiya
PKG_ORGA ?= com.tikiya.orga
PKG_MOBILE_OLD ?= com.example.app_mobile
PKG_ORGA_OLD ?= com.example.tikiya_orga

.PHONY: build android app app_orga clean app_clean web web_mobile web_orga

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
	$(COMPOSE_CMD) build android_build_mobile android_build_organisateur
	$(call export_build,$(IMAGE_MOBILE),./App_mobile)
	$(call export_build,$(IMAGE_ORGA),./App_mobile_organisateur)

# Start Android Studio emulator (local)
android:
	@if [ -z "$(ANDROID_SDK_ROOT)" ]; then echo "ANDROID_SDK_ROOT introuvable"; exit 1; fi
	@if [ ! -x "$(EMULATOR)" ]; then echo "Emulator introuvable: $(EMULATOR)"; exit 1; fi
	@if [ ! -x "$(ADB)" ]; then echo "ADB introuvable: $(ADB)"; exit 1; fi
	@serial=$$($(ADB_SERIAL_CMD)); \
	 if [ -n "$$serial" ]; then echo "Emulateur déjà actif: $$serial"; exit 0; fi; \
	 echo "Lancement AVD: $(AVD_NAME)"; \
	 $(EMULATOR_ENV) $(EMULATOR) -avd $(AVD_NAME) $(EMULATOR_ARGS) > $(EMULATOR_LOG) 2>&1 & \
	 echo "Log emulateur: $(EMULATOR_LOG)"; \
	 timeout $(ADB_WAIT_TIMEOUT) sh -c 'while [ -z "$$($(ADB_SERIAL_CMD))" ]; do sleep 2; done' \
	   || (echo "Emulateur non démarré"; tail -n 200 $(EMULATOR_LOG); exit 1); \
	 serial=$$($(ADB_SERIAL_CMD)); \
	 $(ADB) -s $$serial wait-for-device; \
	 echo "Emulateur prêt"

# Build and install App_mobile APK via Docker on the running emulator
app: android
	$(COMPOSE_CMD) build android_build_mobile
	$(call export_build,$(IMAGE_MOBILE),./App_mobile)
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi; \
	 for pkg in $(PKG_MOBILE) $(PKG_MOBILE_OLD); do $(ADB) -s $$serial uninstall $$pkg >/dev/null 2>&1 || true; done; \
	 $(ADB) -s $$serial install -r $(PWD)/App_mobile/build/app/outputs/flutter-apk/app-release.apk

# Build and install App_mobile_organisateur APK via Docker on the running emulator
app_orga: android
	$(COMPOSE_CMD) build android_build_organisateur
	$(call export_build,$(IMAGE_ORGA),./App_mobile_organisateur)
	@serial=$$($(ADB_SERIAL_CMD)); if [ -z "$$serial" ]; then echo "Aucun emulateur détecté"; exit 1; fi; \
	 for pkg in $(PKG_ORGA) $(PKG_ORGA_OLD); do $(ADB) -s $$serial uninstall $$pkg >/dev/null 2>&1 || true; done; \
	 $(ADB) -s $$serial install -r $(PWD)/App_mobile_organisateur/build/app/outputs/flutter-apk/app-release.apk

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

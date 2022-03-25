CORE_DEPENDS := \
	mutagen \
	sgmllib3k \
	feedparser
PLUGINS_DEPENDS := \
	pyinotify \
	musicbrainzngs \
	dbus-python \
	paho-mqtt

APP_ID := io.github.quodlibet.QuodLibet
RUNTIME_VERSION := 41

BUILD := build
DIST := dist
REPO := $(BUILD)/repo

all: $(REPO) dist-flatpaks

install: $(BUILD)/$(APP_ID).flatpak $(BUILD)/$(APP_ID).Locale.flatpak
	flatpak install --noninteractive --user $(BUILD)/$(APP_ID).flatpak || true
	flatpak install --noninteractive --user $(BUILD)/$(APP_ID).Locale.flatpak || true

$(REPO): *.yaml
	flatpak-builder --force-clean --repo=$@ $(BUILD)/build --state-dir=$(BUILD)/.flatpak-builder $(APP_ID).yaml
	flatpak build-update-repo $(REPO)

$(BUILD)/$(APP_ID).flatpak: $(REPO)
	flatpak build-bundle $(REPO) $@ $(APP_ID)

$(BUILD)/$(APP_ID).Locale.flatpak: $(REPO)
	flatpak build-bundle $(REPO) $@ $(APP_ID).Locale --runtime

$(DIST):
	mkdir -p $(DIST)

$(DIST)/%.flatpak: $(BUILD)/%.flatpak $(DIST)
	cp $< $@

dist-flatpaks: $(DIST)/$(APP_ID).flatpak $(DIST)/$(APP_ID).Locale.flatpak

python-modules:
	python3 flatpak-builder-tools/pip/flatpak-pip-generator \
		--cleanup=scripts \
		--output=python-modules \
		--checker-data \
		$(CORE_DEPENDS) \
		$(PLUGINS_DEPENDS)
	python3 flatpak-builder-tools/flatpak-json2yaml.py --force python-modules.json -o python-modules.yaml && rm python-modules.json

setup:
	flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install --noninteractive --user flathub org.gnome.Sdk//$(RUNTIME_VERSION)
	flatpak install --noninteractive --user flathub org.gnome.Platform//$(RUNTIME_VERSION)

check:
	flatpak run org.flathub.flatpak-external-data-checker $(APP_ID).yaml

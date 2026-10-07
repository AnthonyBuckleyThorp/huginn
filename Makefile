APP := /Applications/Huginn.app
BUILT := build/Build/Products/Release/Huginn.app

# Team ID from this Mac's Apple Development certificate; override with `make TEAM=XXXXXXXXXX`.
# Without one, the app is signed ad hoc: it runs, but macOS asks for Screen Recording
# permission again after every rebuild.
TEAM ?= $(shell ./scripts/team-id.sh)
SIGNING := $(if $(TEAM),DEVELOPMENT_TEAM=$(TEAM),CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=)

.PHONY: setup project build install run clean

setup:
	@./scripts/setup.sh

project:
	xcodegen generate --quiet

build: project
	$(if $(TEAM),,@echo "warning: no Apple Development certificate found, signing ad hoc")
	xcodebuild -project Huginn.xcodeproj -scheme Huginn -configuration Release -derivedDataPath build -quiet $(SIGNING) build

install: build
	-pkill -x Huginn; sleep 0.5
	rm -rf $(APP)
	ditto $(BUILT) $(APP)

run: install
	open $(APP)

clean:
	rm -rf build Huginn.xcodeproj

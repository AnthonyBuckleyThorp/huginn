APP := /Applications/Huginn.app
BUILT := build/Build/Products/Release/Huginn.app

.PHONY: setup project build install run clean

setup:
	@./scripts/setup.sh

project:
	xcodegen generate --quiet

build: project
	xcodebuild -project Huginn.xcodeproj -scheme Huginn -configuration Release -derivedDataPath build -quiet build

install: build
	-pkill -x Huginn; sleep 0.5
	rm -rf $(APP)
	ditto $(BUILT) $(APP)

run: install
	open $(APP)

clean:
	rm -rf build Huginn.xcodeproj

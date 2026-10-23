#!/bin/zsh
# Builds Huginn.app with only the Command Line Tools (swiftc + the macOS SDK),
# for Macs without the full Xcode install. Same sources, bundle ID and
# Info.plist keys as project.yml (keep the two in step). Builds for this Mac's
# architecture only. Signs with your Apple Development certificate if you have
# one (choose one with HUGINN_IDENTITY=<SHA-1 or name>), otherwise ad hoc, in
# which case macOS asks for Screen Recording again after each rebuild.
set -euo pipefail
cd "${0:A:h}/.."

sdk=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null) || {
  echo "error: no macOS SDK found. Install the Command Line Tools for macOS 26: xcode-select --install" >&2
  exit 1
}
arch=$( [[ $(sysctl -n hw.optional.arm64 2>/dev/null) == 1 ]] && echo arm64 || echo x86_64 )

out=build/clt
app=$out/Huginn.app
rm -rf $out && mkdir -p $app/Contents/MacOS

swiftc -O -wmo -swift-version 5 -parse-as-library \
  -target "$arch-apple-macos26.0" -sdk "$sdk" \
  -module-name Huginn Huginn/*.swift -o $app/Contents/MacOS/Huginn

cat > $app/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleIdentifier</key><string>com.anthony.huginn</string>
  <key>CFBundleName</key><string>Huginn</string>
  <key>CFBundleDisplayName</key><string>Huginn</string>
  <key>CFBundleExecutable</key><string>Huginn</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>LSUIElement</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

identity=${HUGINN_IDENTITY:-$(security find-identity -v -p codesigning | awk '/"Apple Development/ { print $2; exit }')}
if [[ -z "$identity" ]]; then
  echo "warning: no Apple Development certificate found, signing ad hoc"
  echo "         (have one but still see this? install Apple's WWDR G3 intermediate certificate: see scripts/setup.sh)"
  identity=-
fi
codesign --force --sign "$identity" $app
echo "built $app"

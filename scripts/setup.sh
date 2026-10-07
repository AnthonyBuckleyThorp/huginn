#!/bin/zsh
# Gets a Mac ready to build Huginn, then builds, installs and launches it.
# Safe to re-run: each step checks first and only acts when something is missing.
set -u
cd "$(dirname "$0")/.."

ok()   { print -P "%F{green}✓%f $1" }
fix()  { print -P "%F{yellow}✗%f $1"; print "  → $2"; FAILED=1 }
FAILED=0

# 1. Xcode installed and selected
if [[ ! -d /Applications/Xcode.app ]]; then
  fix "Xcode is not installed" "Install it from the App Store (open 'macappstore://apps.apple.com/app/id497799835'), open it once, then re-run this script."
  exit 1
fi
if [[ "$(xcode-select -p)" != /Applications/Xcode.app/* ]]; then
  fix "Command-line tools are not using Xcode" "Run: sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi
ok "Xcode $(xcodebuild -version 2>/dev/null | head -1 | cut -d' ' -f2)"

# 2. Licence accepted and first-launch components installed
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  fix "Xcode setup is unfinished" "Open Xcode, accept the licence and let it install components, then re-run."
  exit 1
fi
ok "Xcode licence accepted"

# 3. XcodeGen
if ! command -v xcodegen >/dev/null; then
  if command -v brew >/dev/null; then
    brew install xcodegen >/dev/null && ok "Installed XcodeGen"
  else
    fix "XcodeGen is missing and Homebrew isn't installed" "Install Homebrew from https://brew.sh, then re-run."
    exit 1
  fi
else
  ok "XcodeGen"
fi

# 4. Apple's current intermediate certificate (without it, signing identities show as invalid)
if ! security find-certificate -a -c "Apple Worldwide Developer Relations" -p 2>/dev/null \
     | openssl crl2pkcs7 -nocrl -certfile /dev/stdin 2>/dev/null \
     | openssl pkcs7 -print_certs -noout 2>/dev/null | grep -q "OU=G3"; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/AppleWWDRCAG3.cer" https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer \
    && security import "$tmp/AppleWWDRCAG3.cer" -k ~/Library/Keychains/login.keychain-db >/dev/null \
    && ok "Installed Apple WWDR G3 intermediate certificate"
  rm -rf "$tmp"
else
  ok "Apple WWDR G3 intermediate certificate"
fi

# 5. A valid Apple Development signing identity
if ! security find-identity -v -p codesigning | grep -q "Apple Development"; then
  fix "No valid Apple Development certificate" "In Xcode → Settings → Accounts, sign in with the same Apple ID, click Manage Certificates…, then + → Apple Development. Re-run."
  exit 1
fi
ok "Apple Development signing certificate"

# 6. Ctrl+Space must not be taken by the input-source shortcut (warning only)
if defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null \
   | grep -A1 '^ *60 =' | grep -q 'enabled = 1'; then
  fix "Ctrl+Space is still bound to \"Select the previous input source\"" "Untick it in System Settings → Keyboard → Keyboard Shortcuts → Input Sources."
fi

# 7. Build, install and launch
print "\nBuilding Huginn…"
make run 2>&1 | grep -E 'error|BUILD FAILED' && { print "Build failed."; exit 1 }
sleep 1
if pgrep -xq Huginn; then
  ok "Huginn is installed in /Applications and running in the menu bar"
  print "  Press Ctrl+Space. The first time, grant Screen Recording permission, reopen Huginn, and try again."
else
  print "Huginn didn't start; try: open /Applications/Huginn.app"
  exit 1
fi
exit $FAILED

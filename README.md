# Huginn

**A Snipping Tool–style screenshot flow for the Mac.** Press Ctrl+Space, drag over what matters, draw a red box or circle round it, press Space. The marked-up image is on your clipboard, ready to paste into Slack, Notion or email, and a PNG is saved to ~/Pictures/Screenshots. Under five seconds, all from the keyboard.

For anyone who finds the built-in macOS screenshot markup too many clicks for a quick "look at this bit":

- **One shortcut, one drag.** Uses the native macOS crosshair, any display, full Retina resolution.
- **No toolbar.** R for a box, P for a pen, Cmd+Z to undo. Red, medium stroke, nothing to configure.
- **Space to finish.** Copies, saves and closes in one keypress; Esc throws it away.
- **Lives in the menu bar.** No Dock icon, launches at login, no Accessibility permission needed.

Native Swift, no dependencies, macOS 26+. You build it from source with your own free Apple ID (see below). Design notes are in the [PRD](docs/PRD.md).

## Install on a Mac

No Xcode? See [Without Xcode](#without-xcode) below.

1. Install Xcode from the App Store, open it once and accept the licence.
2. In Xcode → Settings → Accounts, sign in with your Apple ID, then Manage Certificates… → + → Apple Development.
3. Install [Homebrew](https://brew.sh) if it isn't there.
4. Clone and run setup:

   ```
   git clone https://github.com/AnthonyBuckleyThorp/huginn && cd huginn && make setup
   ```

`make setup` checks everything else (XcodeGen, Apple's intermediate certificate, the Ctrl+Space input-source clash), says how to fix anything it can't, then builds, installs to /Applications and launches Huginn. It's safe to re-run.

The build signs with the Apple Development certificate on whichever Mac it runs on, so there's nothing to edit for your own Apple ID.

On the first Ctrl+Space, grant Screen Recording permission, reopen Huginn and try again.

### Without Xcode

Xcode is a big download. Huginn has no dependencies, so the Command Line Tools for macOS 26 (`xcode-select --install`) are enough to build it:

```
git clone https://github.com/AnthonyBuckleyThorp/huginn && cd huginn && make run-clt
```

This compiles with `swiftc` for your Mac's architecture, assembles the app with the same bundle ID and Info.plist keys as `project.yml`, signs it with your Apple Development certificate if you have one (otherwise ad hoc, so Screen Recording is asked for again after each rebuild), installs to /Applications and launches it. No XcodeGen or Homebrew needed. It skips `make setup`'s checks, so if Ctrl+Space does nothing, see the input-source note in `scripts/setup.sh`. Update with `git pull && make run-clt`.

## Update

```
git pull && make run
```

## Keys

| Key | Action |
| --- | --- |
| Ctrl+Space | Capture (anywhere) |
| R / P | Box / pen |
| Cmd+Z / Shift+Cmd+Z | Undo / redo |
| Space | Copy, save to ~/Pictures/Screenshots, close |
| Esc | Discard and close |

## Licence

[MIT](LICENSE). No third-party code; the project file is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

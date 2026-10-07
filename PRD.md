# Huginn — Screenshot Markup Tool PRD

Oct 6, 2026 · @Anthony

## Overview

Huginn is a personal macOS menu bar app: press Ctrl+Space, drag to capture part of the screen, mark it up with a red box or a pen, then press Space to copy it to the clipboard and close. The whole loop should take under five seconds and need no mouse trips to a toolbar.

The macOS built-in screenshot markup is too many steps for quick "look at this bit" shares into Slack, Notion and email. The Windows Snipping Tool flow is the benchmark. The app is for one user (Anthony), on his own Mac, and will not be distributed.

## Goals and non-goals

**Goals for v1**

- Capture to markup window in one shortcut plus one drag.
- Fully keyboard-driven markup: no toolbar, no settings to touch day to day.
- Copy, auto-save and close in one keypress.
- Feels instant: markup window appears with no visible delay after the drag.

**Non-goals for v1**

- Distribution to anyone else, App Store or notarisation.
- Colour, thickness or style choices.
- Arrows, text labels, blur or redaction.
- A custom capture overlay (magnifier, window snapping beyond what macOS gives).
- Screenshot history or a library view.

## Core user flow

1. Anthony presses **Ctrl+Space** from any app.
2. The native macOS crosshair appears; he drags a rectangle. Esc at this stage cancels with nothing opened.
3. The markup window opens immediately, showing the capture at its real size, with the rectangle tool active.
4. He drags to draw red boxes, or presses **P** to switch to the pen and draw freehand circles or lines; **R** switches back. **Cmd+Z** undoes the last mark.
5. He presses **Space**: the marked-up image goes to the clipboard, a PNG is saved to ~/Pictures/Screenshots, and the window closes.
6. He pastes into Slack, Notion, email or anywhere else.

At any point in the markup window, **Esc** discards everything and closes, with no save and no clipboard change.

## Functional requirements

**Capture**

- Global hotkey Ctrl+Space triggers capture from any app, including full-screen apps.
- Selection uses the native macOS interactive capture (drag a region; Space toggles window mode as macOS normally does).
- Works on any connected display and keeps full Retina resolution.
- If the selection is cancelled, nothing opens and nothing is saved.
- A second Ctrl+Space while a markup window is open is ignored; only one markup window at a time.

**Markup window**

- Opens in front, focused, on the display where the capture was taken, sized to the image (scaled down to fit the screen if larger).
- Rectangle tool is the default on every open: click-drag draws a red outline box, medium stroke.
- Pen tool (P): click-drag draws a freehand red line, medium stroke, smoothed.
- R and P switch tools; the cursor shows which tool is active.
- Cmd+Z undoes the last mark; Shift+Cmd+Z redoes.
- Colour and stroke are fixed: red, medium (about 4 pt at 1x, scaled for Retina).

**Copy, save and close (Space)**

- Flattens marks onto the image at full original resolution.
- Writes the PNG to the clipboard.
- Saves the same PNG to ~/Pictures/Screenshots, creating the folder if missing. Filename: `Screenshot YYYY-MM-DD at HH.MM.SS.png`.
- Closes the window and returns focus to the previous app.
- If saving fails, the clipboard copy still happens and a brief notification reports the save error.

**Cancel (Esc)**

- Closes the window immediately with no confirmation, no save and no clipboard change.

**App shell**

- Menu bar icon only, no Dock icon.
- Menu items: Capture, Open Screenshots Folder, Launch at Login (toggle, on by default), Quit.
- Launches at login.

## Keyboard shortcuts

| Key | Where | Action |
| --- | --- | --- |
| Ctrl+Space | Anywhere (global) | Start capture |
| Esc | During selection | Cancel capture |
| R | Markup window | Rectangle tool (default) |
| P | Markup window | Pen tool |
| Cmd+Z / Shift+Cmd+Z | Markup window | Undo / redo |
| Space | Markup window | Copy, save and close |
| Esc | Markup window | Discard and close |

Ctrl+Space is macOS's default "Select the previous input source" shortcut, so that must be switched off (see setup). Space and R/P will need rethinking only if a text tool is added later.

## Technical approach

A native Swift app (SwiftUI app lifecycle, AppKit for the hotkey and markup window), targeting the current macOS release only. Claude Code writes, builds (via `xcodebuild`) and debugs it on Anthony's Mac.

| Component | Approach | Notes |
| --- | --- | --- |
| App shell | Menu bar extra, `LSUIElement` set so no Dock icon | Launch at login via `SMAppService` |
| Global hotkey | Carbon `RegisterEventHotKey` for Ctrl+Space | No Accessibility permission needed; fixed key, so no settings UI |
| Capture | Run `/usr/sbin/screencapture -i -x <temp file>` | Native drag selection; no file written = cancelled |
| Markup window | `NSWindow` hosting a custom `NSView` that draws the image plus a list of marks | Window handles R, P, Space, Esc, Cmd+Z key events |
| Marks | Array of rectangle and path structs, replayed on draw | Undo/redo = move items between two stacks |
| Export | Render image + marks into a bitmap at the capture's pixel size | One PNG used for both clipboard and file |
| Clipboard | `NSPasteboard` with PNG data | Pastes cleanly into Slack, Notion, Gmail |
| Save | Write PNG to ~/Pictures/Screenshots | Folder created on first save |

To keep the project easy for Claude Code to edit, generate the Xcode project from a plain config file (e.g. XcodeGen) rather than hand-editing project files.

## One-off setup

These are the only steps Anthony does by hand; Claude Code handles everything else.

- [ ] Install Xcode from the Mac App Store and open it once to accept the licence.
- [ ] Sign into his Apple ID in Xcode (Settings → Accounts) for free personal signing.
- [ ] Install Claude Code on the Mac.
- [ ] Untick "Select the previous input source" in System Settings → Keyboard → Keyboard Shortcuts → Input Sources.
- [ ] On first capture, grant Screen Recording permission when prompted.

Known friction: recent macOS versions periodically re-confirm Screen Recording permission. Signing every build with the same Apple ID stops macOS forgetting the permission between rebuilds.

## Acceptance criteria

v1 is done when every box below passes on Anthony's Mac.

- [ ] Ctrl+Space starts capture from Slack, Chrome, Notion and a full-screen app.
- [ ] Esc during selection cancels with nothing opened or saved.
- [ ] Markup window appears within half a second of releasing the drag.
- [ ] Rectangle tool is active on open; dragging draws a red outline box.
- [ ] P then drag draws a freehand red line; R returns to rectangles.
- [ ] Cmd+Z removes the last mark; Shift+Cmd+Z restores it.
- [ ] Space puts the marked-up image on the clipboard, pastes correctly into Slack and Notion, and closes the window.
- [ ] The same image appears as a PNG in ~/Pictures/Screenshots with a timestamped name.
- [ ] Pasted and saved images are full Retina resolution, with marks in the right place.
- [ ] Esc in the markup window closes it with no clipboard change and no file saved.
- [ ] Captures on a second display open on that display and export correctly.
- [ ] App starts at login and shows only a menu bar icon.

## Later, not v1

- Custom capture overlay (magnifier, dimming, instant handoff), replacing native selection.
- Arrows, text labels, blur or redaction. A text tool means Space and R/P must not fire while typing.
- Colour and thickness choices.
- Rebindable shortcuts in a settings window.
- Recent-captures menu in the menu bar.
- Sharing with colleagues, which needs a paid Apple Developer account (£79/year) and notarisation.

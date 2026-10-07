# Huginn

Menu bar screenshot markup for macOS. Ctrl+Space, drag, mark up, Space to copy. See [PRD.md](PRD.md).

## Install on a Mac

1. Install Xcode from the App Store, open it once and accept the licence.
2. In Xcode → Settings → Accounts, sign in with your Apple ID, then Manage Certificates… → + → Apple Development.
3. Install [Homebrew](https://brew.sh) if it isn't there, then sign in to GitHub (the repo is private):

   ```
   brew install gh && gh auth login
   ```

4. Clone and run setup:

   ```
   gh repo clone AnthonyBuckleyThorp/huginn && cd huginn && make setup
   ```

`make setup` checks everything else (XcodeGen, Apple's intermediate certificate, the Ctrl+Space input-source clash), says how to fix anything it can't, then builds, installs to /Applications and launches Huginn. It's safe to re-run.

On the first Ctrl+Space, grant Screen Recording permission, reopen Huginn and try again.

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

# Vim BTW

> Vim BTW is a macOS menu bar app that updates Discord Rich Presence when you are using Vim in Terminal or Ghostty.

## Overview

Vim BTW detects when Vim is running and publishes a Discord Rich Presence status so people can see that you are editing in Vim. When Vim is not running but a supported terminal is open, it shows an idle terminal status. When no supported terminal is running, it clears your Discord presence.

The app is written in Swift, runs as a macOS menu bar utility, and talks to Discord through local IPC instead of the deprecated Discord RPC library.

## Features

- Updates Discord Rich Presence from a native macOS menu bar app
- Shows `Editing in Vim` with the detected filename when Vim is running
- Shows idle terminal status when Terminal or Ghostty is open and Vim is not running
- Clears presence when no supported terminal is running
- Tracks a continuous Vim session timer instead of resetting every update
- Lets you enable or disable presence from the menu bar
- Lets you set or change the Discord Application ID from the menu bar
- Reconnects when Discord restarts
- Supports Apple Terminal and Ghostty

## Requirements

- macOS 13 or newer
- Swift toolchain / Xcode command line tools
- Discord desktop app
- A Discord application with Rich Presence assets configured
- Vim running as a `vim` process

## Installation

Clone the repo:

```sh
git clone https://www.github.com/m-tedeschi/vim-btw.git
cd vim-btw
```

Build the app:

```sh
chmod +x build.sh
./build.sh
```

The build creates:

```text
Vim BTW.app
```

You can move the app wherever you want, or add it to Login Items in macOS Settings.

## Usage

Launch `Vim BTW.app`.

Use the menu bar item to:

- Set your Discord Application ID
- Enable or disable Rich Presence updates
- Refresh presence immediately
- Quit the app

Vim BTW checks for supported terminals and Vim periodically. If Discord is closed, the app keeps running and reconnects when Discord is available again.

## Future Improvements

- Add Privacy Mode to hide the current filename
- Improve behavior when multiple Vim windows are open
- Improve behavior for Vim running inside tmux sessions
- Add configurable terminal process names
- Add configurable update interval

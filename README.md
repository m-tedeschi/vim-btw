# vim-btw
Discord Rich Presence for Vim (by the way)

## About
Are you tired of having to manually mention to others that you use Vim as your text editor?
Do you want people to *know* that you don't need fancy GUIs, 500 IDE extensions, and other visual slop?
Maybe you don't even know what a mouse is (based) and you've been in a Vim terminal session since the 90's.
The concept of a mouse is so foreign to you, you explain text highlighting using Visual Mode Vim motions.

**Introducing Vim BTW.** A Discord Rich Presence updater so everybody can know that you're in your terminal and you're cooking.
Everybody knows the only thing better than saying "I use Vim by the way" is actually peer programming in Vim with an onlooker.
This program will handle the former for you, guaranteed. Mac users only. Linux users, please report back on portability. Windows users, stick to VS Code or get a new operating system.

## Features
* Updates Discord Rich Presence to show status
    * **Idle:** when the Terminal is open, the status is Idle
    * **Editing:** when Vim is detected being open, the status is "Editing in Vim" and the file name is displayed
* `.zshrc` script for automatic process handling (e.g. ensuring only 1 process
  runs at a time, killing process on terminal close)
* Vim by the way
<img aligh="center" src="assets/vim-btw-demo.png" alt="Vim BTW demo" height="400" width="200"/>

## Installation (macOS Sequoia 15.0.1)
1. You will need the [deprecated Discord RPC library](https://github.com/discord/discord-rpc). Don't even stress homie
2. Set up a new Application in the [Discord Developer Portal](https://discord.com/developers/applications). Assign an icon (I recommend the Vim logo included in the assets folder) and copy the Application ID -- you will need it later
3. Open `vim-btw.c` and modify the `APP_ID` to be your Application ID
4. Compile with g++ on macOS Sequoia 15.0.1:
```
g++ -o vim-btw vim-btw.c -L/usr/local/lib -ldiscord-rpc -I/usr/local/include -framework CoreFoundation -framework AppKit -lc++
```
5. Set up a Vim BTW directory in your user home directory and copy the binary there:
```
mkdir ~/vim-btw
mv vim-btw ~/vim-btw
```
6. Configure `.zshrc` to automagically start/stop Vim BTW:
```
# --- Vim BTW --- #
# Define a file to store the PID of the running `vim-btw` process
VIM_BTW_PID_FILE="$HOME/.vim-btw.pid"

# Function to check if vim-btw is running
is_vim_btw_running() {
    if [ -f "$VIM_BTW_PID_FILE" ]; then
        if kill -0 $(cat "$VIM_BTW_PID_FILE") 2>/dev/null; then
            return 0  # Running
        else
            rm -f "$VIM_BTW_PID_FILE"  # Stale PID file, remove it
        fi
    fi
    return 1  # Not running
}

# Function to start `vim-btw`
start_vim_btw() {
    if ! is_vim_btw_running; then
        echo -n "[vim-btw] Loaded! PID: "
        nohup ~/vim-btw/vim-btw > /dev/null 2>&1 & echo $! > "$VIM_BTW_PID_FILE"
    fi
}

# Function to stop `vim-btw` when the last terminal instance closes
stop_vim_btw() {
    if [[ $(pgrep -x zsh | wc -l) -le 2 ]]; then  # Count active `zsh` processes
        if is_vim_btw_running; then
            echo "[vim-btw] Stopping vim-btw..."
            kill $(cat "$VIM_BTW_PID_FILE") 2>/dev/null
            rm -f "$VIM_BTW_PID_FILE"
        fi
    fi
}

# Ensure `vim-btw` is executable
chmod +x ~/vim-btw/vim-btw

# Start `vim-btw` only if it's not already running
start_vim_btw

# Ensure `vim-btw` exits when the last terminal closes
trap stop_vim_btw EXIT

# --- End Vim BTW --- #
```
7. Reload your terminal. Vim BTW should be running and will update your status accordingly. You can verify that it is running with the following:
```
lsof -c vim-btw
```

## TODO / Known Bugs
* Using the `.zshrc` config causes the Terminal to prompt user to close running
  process on termination
    * TODO: Verify that process management is working well :) and improve it!
* Discord Rich Presence shows timer for how long Vim BTW has been running
    * This timer is not acccurate and resets every 10 seconds due to the
      update rate 
    * TODO: Fix this so that it is one continuous timer for the duration of Terminal session
* This product was cooked up in about 5 minutes using ChatGPT so please
  report any bugs using the issue tracker
* TODO: Verify functionality on other operating systems

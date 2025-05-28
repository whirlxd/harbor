# Installation

Follow these steps to set up time tracking with Hackatime.

## Prerequisites

Before you begin, make sure you have:
* A code editor (VS Code, IntelliJ, Vim, etc.)
* A [Hackatime account](/)

## Install the WakaTime Plugin

Hackatime uses the WakaTime ecosystem for time tracking. Install the appropriate plugin for your editor:

### Visual Studio Code

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "WakaTime"
4. Click Install

### IntelliJ IDEA / PyCharm / WebStorm

1. Go to File → Settings (or IntelliJ IDEA → Preferences on macOS)
2. Select Plugins
3. Search for "WakaTime"
4. Install and restart your IDE

### Vim/Neovim

For Vim users, install vim-wakatime:

```bash
git clone https://github.com/wakatime/vim-wakatime.git ~/.vim/bundle/vim-wakatime
```

### Sublime Text

1. Open Package Control (Ctrl+Shift+P)
2. Type "Install Package"
3. Search for "WakaTime"
4. Install the package

## Configure Your API Key

1. Get your API key from your [Hackatime settings](/my/settings)
2. When prompted by the plugin, enter:
   * **API Key**: Your Hackatime API key
   * **API URL**: `https://hackatime.hackclub.com/api/hackatime/v1`

## Verify Installation

After setup, your coding time should automatically start being tracked. Check your [dashboard](/) to see your stats!

## Troubleshooting

* **Not seeing data?** Make sure your API URL is correctly set
* **Plugin not working?** Try restarting your editor
* **Need help?** Reach out in the [Hack Club Slack](https://hackclub.slack.com)

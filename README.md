# Claude links for herdr

Opens `claude-cli://` links (from a browser, Slack, a doc…) in a new [herdr](https://github.com/herdrdev/herdr)
workspace instead of a new terminal window. Linux and macOS.

> [!WARNING]
> Not tested on macOS yet. The macOS support follows Claude Code's own code but has never run on a Mac.
> Reports are welcome.

## Install

```sh
herdr plugin install gdarmont/herdr-claude-links
herdr plugin action invoke claude-links.install
```

Claude Code registers its `claude-cli://` handler on the first prompt of an interactive session, so send one prompt in
`claude` before the install action. The action also runs at every herdr start.

Requires herdr 0.9.5 or later and a native Claude Code install (tested with 2.1.308). Linux also needs `xdg-mime`.

## Configuration

- **macOS:** leave Claude's `deepLinkTerminal` setting unset. It takes precedence over the plugin.
- **Linux:** nothing to set.

## How it works

Claude's handler runs `claude --handle-uri <url>`, which opens a terminal running `claude` in the link's directory.
The plugin turns that terminal into a herdr workspace with `herdr-term`.

- **Linux:** Claude starts `$TERMINAL -e claude …`. The plugin copies Claude's `.desktop` entry with
  `TERMINAL=herdr-term` and makes the copy the default `claude-cli` handler. Claude's own entry stays untouched, so
  Claude does not register it again.
- **macOS:** Claude ignores `$TERMINAL`. The plugin adds `LSEnvironment` to
  `~/Applications/Claude Code URL Handler.app`: `TERM_PROGRAM=ghostty` makes Claude launch through
  `open -na Ghostty …`, and `PATH` resolves `open` to `macos/open`, which hands the launch to `herdr-term`. Ghostty
  does not need to be installed.

Ctrl+click on a `claude-cli://open` link inside a herdr pane goes through the same path.

## Limits

- Not tested on macOS.
- Built on Claude Code internals read from version 2.1.308, not on a documented API. A Claude update can break it.
- If herdr isn't running, macOS links open in Terminal.app and Linux links open in `x-terminal-emulator`
  (Debian and Ubuntu). Other Linux distributions open nothing until herdr runs.
- Whether herdr detects `claude-cli://` links for Ctrl+click is untested.

## Uninstall

```sh
herdr plugin uninstall claude-links
# Linux
xdg-mime default claude-code-url-handler.desktop x-scheme-handler/claude-cli
rm ~/.local/share/applications/herdr-claude-links.desktop
# macOS
plutil -remove LSEnvironment ~/Applications/"Claude Code URL Handler.app"/Contents/Info.plist
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/"Claude Code URL Handler.app"
```

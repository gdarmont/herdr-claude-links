#!/bin/sh
# Routes claude-cli:// links through herdr-term without failing Claude's check that its handler is registered, so
# Claude doesn't overwrite the change. Runs at every herdr start: the plugin root moves on update.
set -eu
if [ "$(uname)" = Darwin ]; then
  # Claude checks only the app's executable symlink. Its handler ignores $TERMINAL, but TERM_PROGRAM=ghostty makes it
  # launch links with `open`, which this PATH resolves to macos/open. LaunchServices applies LSEnvironment on URL launches.
  app="$HOME/Applications/Claude Code URL Handler.app"
  plist=$app/Contents/Info.plist
  if [ ! -f "$plist" ]; then
    echo "$app missing: send one prompt in an interactive claude session, then rerun" >&2
    exit 0
  fi
  plutil -replace LSEnvironment -json '{}' "$plist"
  plutil -replace LSEnvironment.TERM_PROGRAM -string ghostty "$plist"
  plutil -replace LSEnvironment.PATH -string "$HERDR_PLUGIN_ROOT/macos:/usr/bin:/bin:/usr/sbin:/sbin" "$plist"
  plutil -replace LSEnvironment.HERDR_BIN_PATH -string "$HERDR_BIN_PATH" "$plist"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
  plutil -extract LSEnvironment json -o - "$plist"
  exit
fi
# Claude rewrites its entry when the exact `Exec="<claude>" --handle-uri %u` line is gone, so leave it alone and make a
# copy that sets $TERMINAL the default handler instead. Claude re-runs xdg-mime only when it rewrites its entry.
apps=${XDG_DATA_HOME:-$HOME/.local/share}/applications
if [ ! -f "$apps/claude-code-url-handler.desktop" ]; then
  echo "$apps/claude-code-url-handler.desktop missing: send one prompt in an interactive claude session, then rerun" >&2
  exit 0
fi
sed -e "s|^Exec=|Exec=env \"TERMINAL=$HERDR_PLUGIN_ROOT/herdr-term\" \"HERDR_BIN_PATH=$HERDR_BIN_PATH\" |" \
  -e 's|^Name=.*|& (herdr)|' "$apps/claude-code-url-handler.desktop" >"$apps/herdr-claude-links.desktop"
xdg-mime default herdr-claude-links.desktop x-scheme-handler/claude-cli
grep '^Exec=' "$apps/herdr-claude-links.desktop"

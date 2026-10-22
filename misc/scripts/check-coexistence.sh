#!/usr/bin/env bash
set -euo pipefail
fork=$1
upstream=$2
combined=$3

test -x "$combined/bin/rio"
test -x "$combined/bin/nrio"
test ! -e "$fork/bin/rio"
test -f "$combined/share/applications/com.yazelix.nova-rio.desktop"
test -f "$combined/share/icons/hicolor/scalable/apps/nrio.svg"
grep -Fx 'Exec=nrio' "$fork/share/applications/com.yazelix.nova-rio.desktop"
grep -Fx 'StartupWMClass=com.yazelix.nova-rio' "$fork/share/applications/com.yazelix.nova-rio.desktop"

export HOME="$PWD/account"
export XDG_CONFIG_HOME="$HOME/xdg"
unset NRIO_CONFIG_HOME RIO_CONFIG_HOME
mkdir -p "$HOME"
case "$(uname)" in
  Darwin) config="$HOME/.config" ;;
  *)
    config="$XDG_CONFIG_HOME"
    grep -Fq VK_ADD_DRIVER_FILES "$fork/bin/nrio"
    if grep -Fq VK_ICD_FILENAMES "$fork/bin/nrio"; then exit 1; fi
    ;;
esac
"$upstream/bin/rio" --write-config
cp "$config/rio/config.toml" upstream.toml
export RIO_CONFIG_HOME="$config/rio"
"$fork/bin/nrio" --write-config
test -s "$config/nrio/config.toml"
cmp upstream.toml "$config/rio/config.toml"

export NRIO_CONFIG_HOME="$HOME/explicit-nova"
"$fork/bin/nrio" --write-config
test -s "$NRIO_CONFIG_HOME/config.toml"
printf '# user-owned Nova config\n' > "$NRIO_CONFIG_HOME/config.toml"
"$fork/bin/nrio" --write-config
grep -Fx '# user-owned Nova config' "$NRIO_CONFIG_HOME/config.toml"
cmp upstream.toml "$config/rio/config.toml"

if test -d "$fork/Applications"; then
  test ! -e "$fork/Applications/Rio.app"
  plist="$fork/Applications/NovaRio.app/Contents/Info.plist"
  test -x "$fork/Applications/NovaRio.app/Contents/MacOS/nrio"
  grep -F 'com.yazelix.nova-rio' "$plist"
fi

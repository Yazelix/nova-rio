# Nova Rio fork

Nova Rio is temporary. It retires when Nova no longer needs it: when upstream
Rio carries every delta below (or an equivalent), or when Nova replaces Nova
Rio with Zellij's own terminal. Each delta lists its own removal condition.
No delta has been proposed upstream yet, and that may never happen: as of
October 2026, Zellij's own terminal window is close to release.

This is Yazelix Nova's minimal [Rio](https://github.com/raphamorim/rio)
fork. The active `edge` branch starts from exact upstream revision
`b2e7c38bdc56bb86b346ca4f37b9aeaa5151d790` (Rio 0.5.20) and carries only
twelve behavioral deltas:

- Standalone distribution uses `nrio`, independent `nrio` config directories,
  `NRIO_CONFIG_HOME`, and the `Nova Rio` / `com.yazelix.nova-rio` application
  identity. The Nix overlay exports `nrio` without overriding `pkgs.rio`.
  Retire this identity delta when the fork is removed or upstream owns an
  independently selectable distribution identity.
- Nova's terminal look is the built-in base configuration
  (`rio-backend/src/config/nova/`): borderless plain window, 0.70 opacity with
  blur and cell opacity, JetBrains Mono 16 with Nerd Font and Noto symbol maps,
  line height 1.12, trail cursor, and adaptive `nova-dark` / `nova-light`
  palettes. The user's `config.toml` overlays it key by key: tables merge, other
  values replace, and a `theme` without `adaptive-theme` drops the adaptive
  palettes. Explicit `[colors]` keys override the selected palettes. A missing
  or invalid file falls back to the embedded base, without loading user themes.
  Themes in the config directory's `themes` win over the built-in Nova palettes.
  The Nix package supplies the fonts; other builds find them by family name.
  Retire this delta with the `nrio` identity.

- Alternate-screen `CSI 2 J` clears obsolete direct Kitty placements. Remove
  this when upstream preserves the same main-screen scrollback boundary.
- Linux Vulkan image textures wait for submitted GPU work before freeing their
  descriptors and pixels on deletion, replacement, eviction, or shutdown. Remove
  this when upstream protects the same image lifetime. The upstream `b2e7c38`
  destructor frees live descriptors; Yazi preview cleanup reproduces validation
  error `VUID-vkDestroyDescriptorPool-descriptorPool-00303`. Verify image/video
  switching and popup hide/reopen in a fresh Rio with Vulkan validation enabled.
  Presentation semaphores belong to swapchain images, rather than frame slots,
  so reacquiring the image gates reuse. Intel Wayland reproduces upstream's
  `VUID-vkQueueSubmit-pSignalSemaphores-00067`; retain this correction until
  upstream follows the same swapchain ownership through resize and shutdown.
- Odd and even vertical grid remainders are balanced through one shared grid
  origin. Remove this when upstream uses an equivalent origin for paint,
  input, graphics, cursors, and IME.
- Explicit backgrounds of Unicode upper/lower half blocks (`▀` / `▄`) stay
  opaque, matching their foreground samples, so `window.opacity-cells = true`
  does not stripe terminal artwork. Default-background sparse halves and
  ordinary TUI backgrounds retain their existing transparency. This corrects
  upstream behavior present in `b2e7c38`; current upstream `59203ccd` retains
  the same alpha routing in `rio-grid`. Remove this when upstream composites
  both samples consistently without changing normal text opacity.
- The compact quit prompt uses Nova's rounded orange treatment and measured,
  balanced spacing. Remove this when upstream styling is accepted as-is or
  exposes a native styling surface.
- `--theme-mode dark|light` selects the configured adaptive palette at launch
  and remains authoritative across config reloads. Remove this when upstream
  exposes an equivalent launch override.

- Native hints share Unicode-aware grid spans across mouse and keyboard input,
  follow terminal soft wraps, preserve configured OSC 8 actions and URI fields,
  and refresh hover feedback on modifier changes. Linux defaults to Ctrl-click;
  macOS retains Super-click. Link presses own their release ahead of application
  mouse reporting, and drags or stale targets cancel activation. Remove this
  delta when upstream provides the same matching and gesture behavior, with the
  accepted modifier available through native configuration.

- Cursor trails obey the existing visibility, blink, focus, and IME policy.
  Hidden cursors discard their trail; the next visible position starts fresh.
  New animations request frames until they settle. Remove this delta when
  upstream passes the same hidden-cursor and idle-animation regressions.

- Synchronized updates buffer drawing immediately after the begin marker,
  including payload in the same PTY read. The existing timeout and size bounds
  remain authoritative. Remove this delta when upstream passes the same
  chunk-boundary regression, including split Unicode and frame markers.

- `--config-editor` validates TOML from stdin without loading assets or opening a
  window, then prints a version-1 TOML inventory of eight common global settings.
  Defaults are the effective values over Nova's built-in base, and accepted blur
  choices come from native config types; the complete native parser validates
  each candidate. Platform overrides retain precedence.
  This is RIO-CONFIG-UI-001, consumed by Nova Ratconfig. It is a finite editor
  surface, not a complete schema or an asset-availability check. Remove this
  delta when upstream provides an equivalent headless inventory and validator.

The config-editor mechanism was reviewed against upstream `b2e7c38` and
`6b0f5c8a`: the existing `--write-config` writes a file but provides no editor
inventory or candidate validation. The editor adds no dependencies.
Run its contract with `cargo test -p rio-backend -p rioterm --features rioterm/wgpu config_editor_uses_native_defaults_and_validation`.
The base overlay regressions are
`cargo test -p rio-backend -p rioterm --features rioterm/wgpu nova_`.

The half-block regression is
`cargo test -p rioterm --features wgpu half_block_compositing`.
Run `python3 misc/scripts/test-half-block-opacity.py` in a fresh candidate Rio
with at least 14 rows, `window.opacity = 0.7`, and `window.opacity-cells = true`:
equal-color columns must be flat, distinct samples must reverse between
upper/lower blocks, and sparse halves and normal text backgrounds must retain
translucency. Repeat
with odd/even cell heights, full opacity, and cell opacity disabled. Selection
and cursor colors retain their existing overrides. The policy keeps explicitly
colored half-block artwork opaque; uniformly translucent artwork would require
coverage-aware compositing rather than applying alpha to two overlaid passes.

Nova consumes exact commits rather than a moving branch. The crates, native
configuration schema, terminal type (`rio` / `xterm-rio`), and all behavior
outside these twelve deltas remain upstream-owned. Mars features and Yazelix
Cursors are intentionally absent.

The hyperlink mechanism was reviewed against upstream `b2e7c38` and historical
Mars commits `2177a794e7` (matching) and `9dc93ee46e` (paired click ownership).
Rio's native hints, grid text/wrap helpers, and structured platform opener remain
the owners; no Mars input subsystem or shell launcher is imported.

Upstream `b2e7c38` reproduces the hidden-cursor defect. The fork was also checked
with Yazi and timing-stressed Codex through Nova Zellij. Run the regression with
`cargo test -p rioterm --features wgpu hidden_trail_restarts` and the visual probe
with `python3 misc/scripts/test-cursor-trail.py` in the installed terminal.
Hidden phases must show no cursor; revealing it must not animate from the hidden
position, and visible moves must settle while terminal output is idle.
Synchronized repaint phases must keep the visible cursor steady. Their parser
regression is `cargo test -p rio-vt sync_update_buffers_payload`.

## Install beside upstream Rio

The supported fork installation is the Nix flake on Linux and macOS:

```sh
nix profile add github:Yazelix/nova-rio/edge#nrio
nrio
```

Pin an exact commit in a consumer lock file. Home Manager users add
`inputs.nova-rio.packages.${pkgs.stdenv.hostPlatform.system}.nrio` to
`home.packages`; keep the upstream Rio package and configuration independent.
The overlay exports `pkgs.nrio`, leaving `pkgs.rio` alone.

The fork reads `$XDG_CONFIG_HOME/nrio/config.toml` on Linux (default
`~/.config/nrio/config.toml`) and `~/.config/nrio/config.toml` on macOS.
`NRIO_CONFIG_HOME` overrides that directory. Upstream `RIO_CONFIG_HOME` has no
effect on the fork. The native configuration schema and `--write-config`
remain Rio's; unset keys take Nova's built-in look. No existing Rio config is
migrated or rewritten.
Linux installs `com.yazelix.nova-rio.desktop`, titled **Nova Rio**, with its own
`nrio` icon and application ID; macOS installs **NovaRio.app** with bundle ID
`com.yazelix.nova-rio` and the `nrio` URL scheme. These coexist with upstream's
identities. The terminal capability names remain upstream's for compatibility.
On Linux, `nrio` adds the package's Mesa Vulkan drivers to standard driver
discovery (`VK_ADD_DRIVER_FILES`), so it opens outside NixOS. Host drivers stay
visible, and an explicit `VK_ADD_DRIVER_FILES`, `VK_DRIVER_FILES` or
`VK_ICD_FILENAMES` keeps Vulkan Loader precedence.

To use a separately installed no-Rio Nova archive, set the fork's native config:

```toml
[shell]
program = "/absolute/path/to/archive/bin/yzx"
args = ["enter"]
```

Use an absolute installed archive path or its stable installation symlink.
The full Nova package already selects its pinned fork and Nova-owned config;
it does not expose `nrio` on PATH. The no-Rio archive still omits Rio.
`nix build .#checks.x86_64-linux.coexistence` checks both packages, independent
config creation, and the Linux Vulkan driver wrapper. Native Darwin checks use `checks.aarch64-darwin.coexistence`;
Linux evaluation alone does not prove macOS behavior. Other inherited upstream
packaging recipes are not a supported Nova release channel.

## Upstream Rio

<!-- LOGO -->
<h1>
<p align="center">
  <img src="https://rioterm.com/assets/rio-logo.png" alt="Rio terminal logo" width="128">
  <br>Rio Terminal
</h1>
  <p align="center">
    Rio is a modern terminal built to run everywhere.
    <br />
    <a href="#about">About</a>
    ·
    <a href="https://rioterm.com/docs/install">Install</a>
    ·
    <a href="https://rioterm.com/docs/config">Config</a>
    ·
    <a href="https://rioterm.com/changelog">Changelog</a>
    ·
    <a href="https://github.com/sponsors/raphamorim">Sponsor</a>
  </p>
</p>

Documentation: [rioterm.com](https://rioterm.com).

## Supporting the Project

If you use and like Rio, please consider sponsoring it: your support helps to cover the fees required to maintain the project and to validate the time spent working on it!

[![Sponsor Rio terminal](https://img.shields.io/github/sponsors/raphamorim?label=Sponsor%20Rio&logo=github&style=for-the-badge)](https://github.com/sponsors/raphamorim)

## Packaging

[![Packaging status](https://repology.org/badge/vertical-allrepos/rio-terminal.svg?columns=3)](https://repology.org/project/rio-terminal/versions)

> Demo with split and CRT on MacOS

![Demo Rio 0.2.0 on MacOS](https://rioterm.com/assets/posts/0.2.0/demo-rio.png)

> Demo with blurred background on Linux

![Demo blurred background](https://rioterm.com/assets/demos/demos-nixos-blur.png)

> Demo of Rio running on a Steam Deck

![Demo of Rio running on a Steam Deck](https://rioterm.com/assets/demos/demo-flatpak-steamdeck.jpg)

## Minimal stable rust version

Rio's MSRV is 1.96.1.

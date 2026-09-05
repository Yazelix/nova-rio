# Nova Rio fork

This is Yazelix Nova's minimal [Rio](https://github.com/raphamorim/rio)
fork. The active `edge` branch starts from exact upstream revision
`b2e7c38bdc56bb86b346ca4f37b9aeaa5151d790` (Rio 0.5.20) and carries only
five behavioral deltas:

- Alternate-screen `CSI 2 J` clears obsolete direct Kitty placements. Remove
  this when upstream preserves the same main-screen scrollback boundary.
- Odd and even vertical grid remainders are balanced through one shared grid
  origin. Remove this when upstream uses an equivalent origin for paint,
  input, graphics, cursors, and IME.
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

Nova consumes exact commits rather than a moving branch. The `rio` executable,
crates, configuration schema, and all behavior outside these five deltas remain
upstream-owned. Mars features and Yazelix Cursors are intentionally absent.

The hyperlink mechanism was reviewed against upstream `b2e7c38` and historical
Mars commits `2177a794e7` (matching) and `9dc93ee46e` (paired click ownership).
Rio's native hints, grid text/wrap helpers, and structured platform opener remain
the owners; no Mars input subsystem or shell launcher is imported.

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

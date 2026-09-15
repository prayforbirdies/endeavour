# Changelog

All notable changes to Endeavour are documented here.

## [2.0.0] - 2026-09-15

Native Apple Silicon rewrite of Shuttle in Swift / AppKit.

### Added
- Native `arm64` menu-bar app (universal build available via `Scripts/build-app.sh universal`).
- Runtime-generated AppleScript for Terminal.app and iTerm (no shipped `.scpt` files);
  supports `new`, `tab`, `current`, and `virtual` (background via `screen`) modes.
- Launch-at-login via the modern `SMAppService` API (macOS 13+).
- Menu items: Edit Configuration…, Reload, Launch at Login, About, Quit.

### Preserved from the original Shuttle
- Drop-in `~/.shuttle.json` config format and `~/.shuttle.path` override.
- Optional second config via `~/.shuttle-alt.json` / `~/.shuttle-alt.path`.
- `~/.ssh/config` + `/etc/ssh_config` host integration, including `Include`
  directives and `# shuttle.<key> <value>` comment metadata.
- `[abc]` sort tags and `[---]` separator tags in names.
- Per-command `theme`, `title`, and `inTerminal`; global `default_theme` and `open_in`.
- URL commands open in the default app.

### Changed
- iTerm support targets the modern stable (v3+) scripting API; the legacy
  "nightly vs stable" distinction was dropped.
- URL detection now requires a real URL scheme so single-word shell commands
  are no longer mistaken for URLs.

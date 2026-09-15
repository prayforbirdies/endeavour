# Super Shuttle

A simple shortcut menu for macOS — a native **Apple Silicon** rewrite of the
long-unmaintained [Shuttle](https://github.com/fitztrev/shuttle) by Trevor
Fitzgerald. Super Shuttle lives in your menu bar and launches SSH sessions and
shell commands in **Terminal.app** or **iTerm**, driven by a simple JSON file.

It runs natively on modern macOS (tested on macOS 27 / Apple Silicon) and is a
drop-in replacement: it reads the **same `~/.shuttle.json`** and `~/.ssh/config`
as the original, so an existing setup works untouched.

## Why this exists

The original Shuttle is an Intel-only Objective-C app that no longer runs on
current macOS. Super Shuttle is a clean Swift/AppKit port that keeps the config
format, SSH-config integration, and menu behavior, while building as a native
`arm64` (or universal) binary.

## Requirements

- macOS 13 or later (Apple Silicon or Intel)
- Xcode command-line tools / Swift 5.9+ to build
- Terminal.app (built in) or iTerm

## Build & install

```bash
# Apple Silicon build
Scripts/build-app.sh

# or a universal (arm64 + x86_64) build
Scripts/build-app.sh universal

# then install
cp -R "build/Super Shuttle.app" /Applications/
open "/Applications/Super Shuttle.app"
```

On first launch, macOS will prompt for **Automation** access so Super Shuttle can
control Terminal/iTerm (System Settings → Privacy & Security → Automation). The
"open in a new tab" mode for Terminal.app also uses an **Accessibility** keystroke,
so grant that too if you use tabs in Terminal.app.

> The bundle is ad-hoc signed. The first time you open it you may need to
> right-click → **Open**, or clear quarantine with
> `xattr -dr com.apple.quarantine "/Applications/Super Shuttle.app"`.

## Configuration

Super Shuttle reads `~/.shuttle.json`. A default is created on first launch if
none exists. Use **Edit Configuration…** from the menu (or edit the file
directly) and the menu reloads automatically when the file changes.

### Global settings

| Key                        | Values                          | Notes                                             |
| -------------------------- | ------------------------------- | ------------------------------------------------- |
| `terminal`                 | `"Terminal.app"` \| `"iTerm"`   | Which terminal to drive.                          |
| `editor`                   | `"default"` \| `nano`/`vi`/…    | `default` opens the JSON in your GUI editor.      |
| `open_in`                  | `"tab"` \| `"new"`              | Default window mode for commands.                 |
| `default_theme`            | profile/theme name              | Fallback theme/profile.                           |
| `launch_at_login`          | `true` \| `false`               | Also toggleable from the menu.                    |
| `show_ssh_config_hosts`    | `true` \| `false`               | Merge hosts from `~/.ssh/config` (default `true`).|
| `ssh_config_ignore_hosts`  | `[ "host", … ]`                 | Exact host names to skip.                          |
| `ssh_config_ignore_keywords` | `[ "kw", … ]`                 | Skip hosts whose name contains any keyword.        |

### Hosts

`hosts` is a list of **commands** and **submenus**. A command (leaf) looks like:

```json
{
  "name": "SSH Prod",
  "cmd": "ssh user@prod.example.com",
  "inTerminal": "new",
  "theme": "Homebrew",
  "title": "prod"
}
```

- `inTerminal`: `"tab"`, `"new"`, `"current"`, or `"virtual"` (background via `screen`).
  Falls back to the global `open_in` when omitted.
- `theme`: Terminal profile / iTerm profile name.
- `title`: window/tab title (defaults to the item name).
- If `cmd` is a URL (e.g. `cifs://server/share`), it opens in the default app.

A submenu is an object mapping a label to a nested list:

```json
{
  "Production": [
    { "name": "web1", "cmd": "ssh web1" },
    { "name": "db1",  "cmd": "ssh db1" }
  ]
}
```

### Name tags

- `[abc]` — a sort hint (3 lowercase letters) that is stripped from the label.
- `[---]` — add a separator line after the item; stripped from the label.

### SSH config integration

Hosts from `~/.ssh/config` (or `/etc/ssh_config`) are added automatically. You
can annotate a host with comment metadata:

```
# shuttle.name Production/web1
Host web1
    HostName web1.example.com
```

The `/` in the name nests it under a **Production** submenu.

## Credits

Super Shuttle is a port of [Shuttle](https://github.com/fitztrev/shuttle) by
Trevor Fitzgerald and its many contributors. MIT licensed.

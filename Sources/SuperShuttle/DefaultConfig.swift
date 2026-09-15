import Foundation

/// The default `~/.shuttle.json` written on first launch when no config exists.
/// Kept intentionally close to the original Shuttle default so existing docs
/// and muscle memory still apply.
enum DefaultConfig {
    static let json = """
    {
      "_comments": [
        "Valid terminals include: 'Terminal.app' or 'iTerm'",
        "In the editor value change 'default' to 'nano', 'vi', or another terminal based editor.",
        "Hosts will also be read from your ~/.ssh/config or /etc/ssh_config file, if available.",
        "Use [aaa] in a name to force sort order, and [---] to add a separator after an item."
      ],
      "editor": "default",
      "launch_at_login": false,
      "terminal": "Terminal.app",
      "open_in": "tab",
      "default_theme": "Homebrew",
      "show_ssh_config_hosts": true,
      "ssh_config_ignore_hosts": [],
      "ssh_config_ignore_keywords": [],
      "hosts": [
        {
          "cmd": "top",
          "name": "Top - Opens in the default window/theme/title"
        },
        {
          "Examples": [
            {
              "cmd": "ssh user@example.com",
              "inTerminal": "tab",
              "name": "SSH Example - Opens in a new tab",
              "title": "example"
            },
            {
              "cmd": "ssh user@shop.example.com",
              "inTerminal": "new",
              "name": "SSH Shop - Opens in a new window",
              "title": "shop"
            }
          ]
        }
      ]
    }
    """
}

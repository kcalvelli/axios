# Adding Custom PWAs to axiOS

axiOS provides a Progressive Web App (PWA) system that allows you to run web applications as desktop apps using Brave browser. This guide shows how to add your own custom PWAs to your personal configuration.

## Quick Start

axiOS includes default PWAs (Google Workspace, Figma, Linear, Hoppscotch, etc.), but you can easily add your own.

### Option 1: Using the Helper Script (Recommended)

```bash
# From your nixos config directory
nix run github:kcalvelli/axios#add-pwa

# Or specify the icon directory explicitly
nix run github:kcalvelli/axios#add-pwa -- /path/to/your/config/pwa-icons

# Or set FLAKE_PATH environment variable
FLAKE_PATH=~/.config/nixos_config nix run github:kcalvelli/axios#add-pwa
```

**Smart directory detection** (in priority order):
1. Command-line argument if provided
2. `FLAKE_PATH` environment variable
3. Git root with `flake.nix` (if run from within a git repo)
4. Common locations: `~/.config/nixos_config/pwa-icons` or `~/.dotfiles/pwa-icons`
5. Current directory: `./pwa-icons`

The script will **prompt you to confirm** the detected path (or customize it).

The script will:
1. Prompt for the PWA URL
2. **Automatically parse the manifest** to extract:
   - Display name
   - Categories
   - Desktop shortcuts (for right-click menus)
3. Fetch the icon automatically
4. Show you the exact Nix code to add to your config
5. Save the icon to your config directory

**Example**: For `https://linear.app`, the script automatically finds:
- Name: "Linear"
- Categories: productivity
- Shortcuts: "New Issue", "Search"
- Icon: Linear's official logo

**Smart config file detection:**
1. Parses your `flake.nix` to find the `userModule` definition (most accurate)
2. Falls back to common filenames: `home.nix`, `user.nix`, `[username].nix`, etc.

**The script provides TWO options for where to add the configuration:**

**Option 1: Direct in your home-manager config**
- Detects your existing home-manager config file (via flake.nix or filename)
- Shows you exactly what to add

**Option 2: Modular pwa.nix file**
- Creates a separate `pwa.nix` for organization
- Shows the import statement to add to your main config

### Option 2: Manual Setup

#### Step 1: Fetch the Icon

```bash
# Create icons directory in your config
mkdir -p ~/.config/nixos_config/pwa-icons

# Fetch icon from the website
nix run github:kcalvelli/axios#fetch-pwa-icon -- \
  https://example.com \
  my-app

# Icon saved to: ./home/resources/pwa-icons/my-app.png
# Copy it to your config:
cp /path/to/axios/home/resources/pwa-icons/my-app.png \
   ~/.config/nixos_config/pwa-icons/
```

#### Step 2: Configure PWA in Home Manager

Add to your home-manager configuration file (common names: `home.nix`, `user.nix`, `[username].nix`, or `home-manager.nix`):

```nix
{
  # Enable PWA support
  axios.pwa = {
    enable = true;

    # Optional: disable default PWAs if you only want custom ones
    includeDefaults = true; # Set to false to disable defaults

    # Point to your icons directory
    iconPath = ./pwa-icons;

    # Define your custom PWAs
    extraApps = {
      my-app = {
        name = "My App";
        url = "https://example.com";
        icon = "my-app"; # Matches filename (without .png)
        categories = [ "Network" "WebApp" ];
      };

      github = {
        name = "GitHub";
        url = "https://github.com";
        icon = "github";
        categories = [ "Development" ];
      };

      # With desktop actions (right-click menu)
      mattermost = {
        name = "Mattermost";
        url = "https://chat.example.com";
        icon = "mattermost";
        categories = [ "Network" "InstantMessaging" ];
        actions = {
          "compose" = {
            name = "New Message";
            url = "https://chat.example.com/messages/new";
          };
        };
      };
    };
  };
}
```

#### Step 3: Rebuild

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

Your custom PWAs will now appear in your application launcher!

## PWA Definition Reference

Each PWA requires these fields:

```nix
pwa-name = {
  # Required fields
  name = "Display Name";           # Shown in launcher
  url = "https://example.com";     # URL to open
  icon = "icon-filename";          # Without .png extension

  # Optional fields
  categories = [ "Category1" "Category2" ];  # Default: [ "Network" ]
  mimeTypes = [ "x-scheme-handler/mailto" ]; # Default: [ ]
  actions = {                      # Desktop actions (right-click menu)
    "action-id" = {
      name = "Action Name";
      url = "https://example.com/action";
    };
  };
}
```

### Common Categories

- **Office**: `[ "Office" ]`
- **Communication**: `[ "Network" "InstantMessaging" ]`
- **Email**: `[ "Office" "Email" ]`
- **Video Conferencing**: `[ "Network" "VideoConference" ]`
- **Development**: `[ "Development" ]`
- **Design**: `[ "Graphics" "VectorGraphics" ]`
- **Project Management**: `[ "Office" "ProjectManagement" ]`

## Icon Management

### Fetching Icons for Multiple PWAs

Create a script in your config directory:

```bash
#!/usr/bin/env bash
# fetch-my-pwas.sh

ICON_DIR="$HOME/.config/nixos_config/pwa-icons"
mkdir -p "$ICON_DIR"

fetch_icon() {
  local url="$1"
  local name="$2"
  nix run github:kcalvelli/axios#fetch-pwa-icon -- "$url" "$name"
  mv "./home/resources/pwa-icons/${name}.png" "$ICON_DIR/"
}

fetch_icon "https://github.com" "github"
fetch_icon "https://gitlab.com" "gitlab"
fetch_icon "https://app.slack.com" "slack"
```

### Using Custom Icons

If the automatic fetcher doesn't work or you have custom icons:

1. Create a 128x128 PNG icon
2. Save it to your `pwa-icons` directory
3. Reference it by filename (without extension) in your PWA definition

```bash
# Convert any image to proper format
magick your-icon.svg -resize 128x128 pwa-icons/my-app.png
```

## File Structure Example

Your config directory should look like:

```
~/.config/nixos_config/
├── flake.nix
├── home.nix                  # Your home-manager config with PWA definitions
├── pwa-icons/                # Your custom PWA icons
│   ├── github.png
│   ├── gitlab.png
│   ├── my-app.png
│   └── slack.png
└── ...
```

## Advanced Usage

### Disabling Default PWAs

If you prefer to define all PWAs yourself:

```nix
{
  axios.pwa = {
    enable = true;
    includeDefaults = false;  # No Google/Microsoft PWAs
    iconPath = ./pwa-icons;
    extraApps = {
      # Your PWAs here
    };
  };
}
```

### MIME Type Associations

Make PWAs handle specific file types:

```nix
{
  gmail = {
    name = "Gmail";
    url = "https://mail.google.com";
    icon = "gmail";
    mimeTypes = [ "x-scheme-handler/mailto" ];  # Handle mailto: links
  };

  google-calendar = {
    name = "Google Calendar";
    url = "https://calendar.google.com";
    icon = "google-calendar";
    mimeTypes = [
      "x-scheme-handler/webcal"
      "text/calendar"
    ];
  };
}
```

### Desktop Actions (Right-Click Menu)

Add quick actions to PWAs:

```nix
{
  gmail = {
    name = "Gmail";
    url = "https://mail.google.com";
    icon = "gmail";
    actions = {
      "Compose" = {
        name = "Compose New Email";
        url = "https://mail.google.com/mail/?view=cm&fs=1&tf=1";
      };
      "Inbox" = {
        name = "Go to Inbox";
        url = "https://mail.google.com/mail/u/0/#inbox";
      };
    };
  };
}
```

## Troubleshooting

### Icon Not Appearing

1. Check icon exists: `ls -lh pwa-icons/your-app.png`
2. Verify filename matches (case-sensitive, no extension in config)
3. Ensure icon is 128x128 PNG format
4. Rebuild after adding icons

### PWA Not Launching

1. Verify URL is accessible
2. Check Brave is installed (comes with desktop module)
3. Look for errors: `journalctl -xeu home-manager-$USER.service`

### Icon Fetch Failed

If automatic fetching fails:
1. Try manually: Visit the website, save the icon
2. Use browser dev tools: Inspect page → find largest icon
3. Convert to PNG: `magick downloaded-icon.ico -resize 128x128 pwa-icons/app.png`

## Examples

See [`pkgs/pwa-apps/pwa-defs.nix`](../pkgs/pwa-apps/pwa-defs.nix) for examples of all default PWAs included in axiOS.

Popular additions users might want:

```nix
{
  # Self-hosted services
  immich = {
    name = "Immich";
    url = "https://photos.example.com";
    icon = "immich";
    categories = [ "Graphics" "Photography" ];
  };

  # Development tools
  vercel = {
    name = "Vercel";
    url = "https://vercel.com";
    icon = "vercel";
    categories = [ "Development" ];
  };

  # Productivity
  asana = {
    name = "Asana";
    url = "https://app.asana.com";
    icon = "asana";
    categories = [ "Office" "ProjectManagement" ];
  };
}
```

## Contributing

Found a great PWA that should be included by default? Submit a PR to [axiOS](https://github.com/kcalvelli/axios) with:
1. Icon (128x128 PNG) in `home/resources/pwa-icons/`
2. Definition in `pkgs/pwa-apps/pwa-defs.nix`
3. Description in the PR explaining why it fits the target user

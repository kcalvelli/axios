{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.programs.davmail;
in
{
  options.programs.davmail = {
    enable = lib.mkEnableOption "DavMail O365/Exchange gateway for IMAP/SMTP access";

    email = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "user@company.com";
      description = ''
        Your Outlook/Office 365 email address.
        Used as a reference in the configuration file.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "O365Interactive"
        "O365Manual"
      ];
      default = "O365Interactive";
      description = ''
        OAuth authentication mode:
        - O365Interactive: Opens browser popup for Microsoft login (requires desktop)
        - O365Manual: Provides URL in terminal for headless systems
      '';
    };

    imapPort = lib.mkOption {
      type = lib.types.port;
      default = 1143;
      description = "Local IMAP port (use in email client)";
    };

    smtpPort = lib.mkOption {
      type = lib.types.port;
      default = 1025;
      description = "Local SMTP port (use in email client)";
    };

    caldavPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "Local CalDAV port (for calendar sync)";
    };

    ldapPort = lib.mkOption {
      type = lib.types.port;
      default = 1389;
      description = "Local LDAP port (for contact sync)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create mutable DavMail configuration (REAL file, not symlink)
    # This file will be modified by DavMail to store OAuth tokens
    home.activation.createDavmailConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      DAVMAIL_CONFIG="$HOME/.davmail.properties"

      # Only create if it doesn't exist (preserves OAuth tokens on rebuild)
      if [ ! -f "$DAVMAIL_CONFIG" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$DAVMAIL_CONFIG")"
        $DRY_RUN_CMD cat > "$DAVMAIL_CONFIG" << 'EOF'
# DavMail Configuration${lib.optionalString (cfg.email != "") " for ${cfg.email}"}
# This file will be automatically updated with OAuth tokens

# Server Configuration
davmail.server=true
davmail.allowRemote=false
davmail.bindAddress=127.0.0.1
davmail.mode=${cfg.mode}
davmail.url=https://outlook.office365.com/EWS/Exchange.asmx

# Port Configuration
davmail.imapPort=${toString cfg.imapPort}
davmail.smtpPort=${toString cfg.smtpPort}
davmail.ldapPort=${toString cfg.ldapPort}
davmail.caldavPort=${toString cfg.caldavPort}

# OAuth Token Persistence (Critical for O365)
davmail.oauth.persistToken=true

# Performance and Logging
davmail.enableKeepAlive=true
davmail.folderSizeLimit=0
log4j.logger.davmail=WARN
log4j.rootLogger=WARN
EOF
        $DRY_RUN_CMD chmod 600 "$DAVMAIL_CONFIG"
        $VERBOSE_ECHO "Created mutable DavMail config: $DAVMAIL_CONFIG"
      else
        $VERBOSE_ECHO "DavMail config already exists (preserving OAuth tokens): $DAVMAIL_CONFIG"
      fi
    '';

    # Systemd user service for background operation
    systemd.user.services.davmail = {
      Unit = {
        Description = "DavMail O365/Exchange Gateway";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.davmail}/bin/davmail %h/.davmail.properties";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    # Helper script for initial OAuth authentication
    home.packages = [
      (pkgs.writeShellScriptBin "davmail-auth" ''
        set -e

        echo "🔐 DavMail O365 Authentication Setup"
        echo "====================================="
        echo ""

        # Check if config file is a symlink (old installation)
        if [ -L "$HOME/.davmail.properties" ]; then
          echo "❌ Error: ~/.davmail.properties is a symlink to the Nix store (read-only)"
          echo "   DavMail needs a writable file to save OAuth tokens."
          echo ""
          echo "   Please delete the symlink and rebuild:"
          echo "   $ rm ~/.davmail.properties"
          echo "   $ home-manager switch"
          echo ""
          echo "   A mutable config file will be created automatically."
          exit 1
        fi

        # Ensure config file exists
        if [ ! -f "$HOME/.davmail.properties" ]; then
          echo "❌ Error: ~/.davmail.properties not found"
          echo "   Run 'home-manager switch' to create the config file"
          exit 1
        fi

        # Stop background service if running
        if systemctl --user is-active --quiet davmail; then
          echo "⏹️  Stopping background DavMail service..."
          systemctl --user stop davmail

          # Wait for service to fully stop (up to 10 seconds)
          echo "⏳ Waiting for service to stop..."
          for i in {1..10}; do
            if ! systemctl --user is-active --quiet davmail; then
              echo "✓ Service stopped"
              break
            fi
            sleep 1
          done

          # Final check - ensure service is really stopped
          if systemctl --user is-active --quiet davmail; then
            echo "❌ Error: Service failed to stop after 10 seconds"
            echo "   Run: systemctl --user stop davmail"
            exit 1
          fi

          # Give ports time to be released
          sleep 2
        fi

        # Verify ports are available (match exact ports, not substrings)
        echo "🔍 Checking if ports are available..."
        if ss -tlnp 2>/dev/null | grep -qE ':(${toString cfg.imapPort}|${toString cfg.smtpPort})([^0-9]|$)'; then
          echo "❌ Error: Ports still in use!"
          echo "   DavMail ports (${toString cfg.imapPort}, ${toString cfg.smtpPort}) are already bound"
          echo "   Run: systemctl --user stop davmail"
          echo "   Check with: ss -tlnp | grep -E ':${toString cfg.imapPort}[^0-9]|:${toString cfg.smtpPort}[^0-9]'"
          exit 1
        fi
        echo "✓ Ports are available"

        echo "🌐 Starting interactive OAuth authentication..."
        echo ""

        ${
          if cfg.mode == "O365Interactive" then
            ''
              echo "A browser window will open for Microsoft login."
              echo "Please log in with your credentials and approve any MFA prompts."
            ''
          else
            ''
              echo "A URL will be displayed in the terminal."
              echo "Copy the URL, open it in a browser, log in, and paste the code back."
            ''
        }

        echo ""
        echo "Press Ctrl+C when you see 'DavMail Gateway listening...'"
        echo ""

        # Run DavMail interactively
        ${pkgs.davmail}/bin/davmail ~/.davmail.properties || true

        echo ""
        echo "✅ Authentication complete! OAuth tokens saved to ~/.davmail.properties"
        echo ""
        echo "🚀 Starting background DavMail service..."
        systemctl --user start davmail

        echo ""
        echo "✓ DavMail is now running in the background"
        echo ""
        echo "Next steps:"
        echo "1. Open GNOME Online Accounts (gnome-online-accounts-gtk)"
        echo "2. Add account → IMAP and SMTP"
        echo "3. Use these settings:"
        echo "   - IMAP Server: 127.0.0.1:${toString cfg.imapPort}"
        echo "   - SMTP Server: 127.0.0.1:${toString cfg.smtpPort}"
        echo "   - Security: None (localhost)"
        echo "   - Username: ${if cfg.email != "" then cfg.email else "your-email@company.com"}"
        echo "   - Password: dummy (any text - DavMail uses OAuth tokens)"
        echo ""
        echo "Check status: systemctl --user status davmail"
      '')

      (pkgs.writeShellScriptBin "davmail-status" ''
        echo "DavMail Status"
        echo "=============="
        echo ""
        systemctl --user status davmail --no-pager
        echo ""
        echo "Configuration: ~/.davmail.properties"
        echo ""
        if grep -q "davmail.oauth.refreshToken" ~/.davmail.properties 2>/dev/null; then
          echo "✅ OAuth tokens present (authenticated)"
        else
          echo "❌ No OAuth tokens found"
          echo "   Run: davmail-auth"
        fi
      '')
    ];
  };
}

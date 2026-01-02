# DavMail Setup for Outlook/Office 365

This guide shows you how to use **DavMail** to access Outlook/Office 365 email with **Geary** (or any IMAP/SMTP email client).

## What is DavMail?

DavMail is a gateway that translates Microsoft's Exchange protocols to standard IMAP/SMTP/CalDAV/CardDAV protocols. This allows you to use standard email clients like Geary with Office 365 accounts that require OAuth2 authentication.

**How it works:**
1. DavMail authenticates to Microsoft Office 365 using OAuth2 (browser login)
2. DavMail stores OAuth tokens and keeps them refreshed
3. Your email client connects to DavMail on localhost using standard IMAP/SMTP
4. DavMail proxies all requests to Office 365 using the OAuth tokens

## Prerequisites

Enable the PIM module with DavMail support:

```nix
# In your host configuration
modules.pim = true;

# In your user.nix (home-manager)
programs.davmail = {
  enable = true;
  email = "your-email@company.com";  # Your Office 365 email
  mode = "O365Interactive";          # Opens browser for login
  # mode = "O365Manual";             # Use this for headless/SSH
};
```

Rebuild your system:
```bash
sudo nixos-rebuild switch
home-manager switch
```

## Step-by-Step Setup

### 1. Initial OAuth Authentication

DavMail needs to authenticate with Microsoft once to obtain OAuth tokens.

Run the authentication helper:
```bash
davmail-auth
```

**What happens:**
- A browser window opens (or you get a URL if using O365Manual mode)
- Log in with your Office 365 credentials
- Complete any MFA challenges (authenticator app, SMS, etc.)
- DavMail saves OAuth tokens to `~/.davmail.properties`
- The background service starts automatically

**Press Ctrl+C** when you see `DavMail Gateway listening...`

### 2. Configure GNOME Online Accounts

Open GNOME Online Accounts:
```bash
gnome-online-accounts-gtk
```

**Add a new account:**
1. Click **+** (Add Account)
2. Select **"IMAP and SMTP"** (NOT "Microsoft Exchange")
3. Fill in the settings:

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | Your Name | Display name for the account |
| **Email** | your-email@company.com | Your Office 365 email |
| **IMAP Server** | `127.0.0.1` | DavMail local proxy |
| **IMAP Port** | `1143` | DavMail's IMAP port |
| **IMAP Security** | **None** | It's localhost, no encryption needed |
| **IMAP Username** | your-email@company.com | Your full email address |
| **SMTP Server** | `127.0.0.1` | DavMail local proxy |
| **SMTP Port** | `1025` | DavMail's SMTP port |
| **SMTP Security** | **None** | It's localhost, no encryption needed |
| **SMTP Username** | your-email@company.com | Your full email address |
| **Password** | `dummy` | **Any text works - DavMail uses OAuth tokens** |

**Important:** The password field is required by GNOME Online Accounts, but DavMail **ignores it completely**. DavMail uses the OAuth2 tokens it obtained during authentication. You can enter any text (e.g., "oauth", "token", or "dummy").

4. Click **Connect** or **Add**

### 3. Launch Geary

Open Geary:
```bash
geary
```

Your Office 365 account will appear automatically from GNOME Online Accounts. Geary will connect via DavMail to your Office 365 mailbox.

## Management Commands

Check DavMail status:
```bash
davmail-status
```

Restart DavMail service:
```bash
systemctl --user restart davmail
```

Stop DavMail service:
```bash
systemctl --user stop davmail
```

View DavMail logs:
```bash
journalctl --user -u davmail -f
```

## Troubleshooting

### "Cannot connect to server" in Geary

**Check if DavMail is running:**
```bash
systemctl --user status davmail
```

**Check for OAuth tokens:**
```bash
grep "davmail.oauth.refreshToken" ~/.davmail.properties
```

If no tokens found, run `davmail-auth` again.

### OAuth tokens expired

OAuth tokens typically last 30-90 days depending on your organization's policies.

**To refresh:**
```bash
davmail-auth
```

This will re-authenticate and save new tokens.

### Browser doesn't open (O365Interactive mode)

If you're on a headless system or the browser fails to launch:

**Switch to O365Manual mode:**
```nix
programs.davmail.mode = "O365Manual";
```

Rebuild and run `davmail-auth` - it will display a URL to copy/paste into a browser.

### "JavaFX not found" error

If O365Interactive mode fails with JavaFX errors, switch to O365Manual mode:

```nix
programs.davmail.mode = "O365Manual";
```

### GNOME Online Accounts won't save the account

Make sure:
1. DavMail is running: `systemctl --user status davmail`
2. You're using **"IMAP and SMTP"** account type, NOT "Microsoft Exchange"
3. Security is set to **"None"** for both IMAP and SMTP
4. Ports are correct: `1143` (IMAP), `1025` (SMTP)

## Calendar and Contacts Sync

DavMail also provides CalDAV and CardDAV for calendar and contacts sync.

**Default ports:**
- CalDAV: `1080`
- CardDAV/LDAP: `1389`

**Note:** GNOME Calendar and GNOME Contacts don't support custom ports via GNOME Online Accounts. For calendar/contact sync with Office 365, use the built-in Exchange support in GNOME Online Accounts or configure Evolution directly.

## Custom Port Configuration

If you need different ports (e.g., to avoid conflicts):

```nix
programs.davmail = {
  enable = true;
  email = "your-email@company.com";
  imapPort = 2143;  # Custom IMAP port
  smtpPort = 2025;  # Custom SMTP port
  caldavPort = 2080;
  ldapPort = 2389;
};
```

**Remember to update GNOME Online Accounts** with the new ports.

## Why Not Use Evolution-EWS?

Evolution-EWS (Exchange Web Services) provides native Office 365 support, but:

- **Geary doesn't support EWS** - Geary is purely an IMAP/SMTP client
- **DavMail works with any IMAP/SMTP client** - More flexibility
- **DavMail handles OAuth2 separately** - Easier to debug authentication issues

If you're using **Evolution** (the full email client), you can use evolution-ews directly via GNOME Online Accounts → Microsoft Exchange. But for **Geary**, DavMail is the solution.

## Technical Details

**What DavMail stores:**
- OAuth access tokens (short-lived, ~1 hour)
- OAuth refresh tokens (long-lived, 30-90 days)
- Account metadata

**Configuration file:** `~/.davmail.properties`

**Security considerations:**
- OAuth tokens are stored in plaintext in `~/.davmail.properties`
- File permissions are `600` (only you can read)
- DavMail only listens on `127.0.0.1` (localhost only)
- No external connections can reach DavMail

**Network traffic:**
- Email client ↔ DavMail: Unencrypted (localhost only)
- DavMail ↔ Office 365: Encrypted (HTTPS)

## See Also

- [GNOME PIM Setup (PIM Module)](../spec-kit-baseline/runbook.md#gnome-online-accounts-setup-pim-module) - General GNOME Online Accounts guide
- [MODULE_REFERENCE.md](MODULE_REFERENCE.md#pim) - PIM module documentation
- [APPLICATIONS.md](APPLICATIONS.md#communication--pim) - Email client options

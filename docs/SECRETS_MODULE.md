# Secrets Module Implementation

## Overview
Comprehensive secrets management module for axiOS providing age-encrypted secrets for both system and home-manager configurations using agenix.

## What Was Created

### NixOS Module (`modules/secrets/`)
- **`default.nix`** - Main module with `secrets.enable` option
- Imports agenix.nixosModules.default for age-encrypted secrets
- Configures SSH identity paths for secret decryption
- Optional automatic secret discovery from a secrets directory
- Installs agenix CLI tool for secret management

**Key Features:**
- **Convention over configuration**: Auto-discover and register `.age` files
- **Sensible defaults**: Uses system SSH host keys for decryption
- **Flexible configuration**: Direct access to `age.secrets` for advanced use

### Home-Manager Module (`home/secrets/`)
- **`default.nix`** - Home-manager secrets configuration
- Imports agenix.homeManagerModules.default
- Manages per-user secrets with user SSH keys
- Auto-enables when system secrets module is enabled
- Optional automatic secret discovery for user-specific secrets

**Key Features:**
- **User-scoped secrets**: Decrypted to `~/.config/agenix/`
- **SSH key integration**: Uses user's SSH keys for decryption
- **Seamless integration**: Automatically enabled with system module

## Usage

### Enable Secrets Module in Host Config
```nix
# In your host configuration
modules = {
  secrets = true;  # Enable secrets management
  # ... other modules
};
```

### Quick Start: Convention Over Configuration

The easiest way to use secrets in axiOS is with the `secretsDir` option:

```nix
# In your host configuration
modules = {
  secrets = true;
};

secrets = {
  secretsDir = ./secrets;  # Directory containing your .age files
};
```

**Directory structure:**
```
your-config/
├── flake.nix
├── secrets/
│   ├── secrets.nix         # Public key definitions
│   ├── ssh-key.age         # Encrypted SSH key
│   ├── wifi-password.age   # Encrypted WiFi password
│   └── api-token.age       # Encrypted API token
└── hosts/
    └── yourhost.nix
```

**What happens automatically:**
- All `.age` files in `secretsDir` are registered as secrets
- Secrets are decrypted to `/run/agenix/<name>` (without `.age` extension)
- System services can reference secrets via `/run/agenix/ssh-key`

### Advanced: Direct age.secrets Configuration

For more control over secret permissions and ownership:

```nix
modules = {
  secrets = true;
};

# Direct age.secrets configuration
age.secrets = {
  ssh-key = {
    file = ./secrets/ssh-key.age;
    mode = "600";
    owner = "root";
    group = "root";
  };

  wifi-password = {
    file = ./secrets/wifi-password.age;
    mode = "640";
    owner = "root";
    group = "networkmanager";
  };

  api-token = {
    file = ./secrets/api-token.age;
    mode = "440";
    owner = "myuser";
    group = "users";
  };
};
```

### Home-Manager User Secrets

User-specific secrets are managed separately:

```nix
# In home-manager configuration (automatically included with secrets module)
secrets = {
  enable = true;  # Auto-enabled if system secrets.enable = true
  secretsDir = ./home-secrets;  # Optional: auto-discover user secrets
};

# Or configure directly
age.secrets = {
  github-token = {
    file = ./secrets/github-token.age;
  };

  ssh-config = {
    file = ./secrets/ssh-config.age;
  };
};
```

**User secrets are decrypted to:** `~/.config/agenix/<name>`

## Creating and Managing Secrets

### Prerequisites

1. **Ensure SSH keys exist:**
```bash
# System host keys (created during NixOS installation)
ls -l /etc/ssh/ssh_host_ed25519_key

# User SSH keys
ls -l ~/.ssh/id_ed25519
```

2. **Create secrets.nix:**
```nix
# secrets/secrets.nix
let
  # User public keys (for encrypting user secrets)
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJoe0... user@host";

  # System host public keys (for encrypting system secrets)
  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbcd... root@host1";
  system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExyz... root@host2";
in
{
  # System secrets - accessible by specified hosts
  "ssh-key.age".publicKeys = [ user1 system1 system2 ];
  "wifi-password.age".publicKeys = [ user1 system1 ];
  "api-token.age".publicKeys = [ user1 system1 system2 ];

  # User secrets - accessible by user
  "github-token.age".publicKeys = [ user1 ];
}
```

### Creating Secrets

```bash
# Navigate to your secrets directory
cd ~/your-config/secrets

# Create or edit a secret (agenix CLI installed with module)
agenix -e ssh-key.age

# This will:
# 1. Create/open the secret in your $EDITOR
# 2. Encrypt it with the public keys defined in secrets.nix
# 3. Save the encrypted .age file
```

### Re-keying Secrets

When adding new hosts or users, re-key existing secrets:

```bash
# Update secrets.nix with new public keys, then:
agenix --rekey
```

## Configuration Options

### System Module Options (`secrets.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable age-encrypted secrets management |
| `identityPaths` | list of paths | `[ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ]` | SSH private keys for decryption |
| `secretsDir` | null or path | `null` | Directory for auto-discovery of `.age` files |
| `installCLI` | bool | `true` | Install agenix CLI tool |

### Home-Manager Module Options (`secrets.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | Auto-enabled with system | Enable user secrets management |
| `identityPaths` | list of strings | `[ "~/.ssh/id_ed25519" "~/.ssh/id_rsa" ]` | User SSH keys for decryption |
| `secretsDir` | null or path | `null` | Directory for auto-discovery of user `.age` files |

## Complete Example

### Flake Configuration
```nix
{
  description = "My NixOS configuration with secrets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    axios.url = "github:kcalvelli/axios";
  };

  outputs = { self, nixpkgs, axios }: {
    nixosConfigurations.myhost = axios.lib.mkSystem {
      hostname = "myhost";
      system = "x86_64-linux";

      formFactor = "desktop";
      homeProfile = "workstation";

      hardware = {
        cpu = "amd";
        gpu = "amd";
      };

      modules = {
        system = true;
        networking = true;
        desktop = true;
        secrets = true;  # Enable secrets module
      };

      # Configure secrets
      secrets = {
        secretsDir = ./secrets;  # Auto-discover secrets
        installCLI = true;       # Install agenix CLI
      };

      # Or use age.secrets directly for fine-grained control
      extraConfig = {
        age.secrets.database-password = {
          file = ./secrets/database-password.age;
          mode = "440";
          owner = "postgres";
          group = "postgres";
        };
      };
    };
  };
}
```

### Using Secrets in Services
```nix
# In your NixOS configuration
services.postgresql = {
  enable = true;
  # Reference the secret
  passwordFile = config.age.secrets.database-password.path;
};

services.wireguard.interfaces.wg0 = {
  privateKeyFile = config.age.secrets.wireguard-key.path;
};

# Environment files for systemd services
systemd.services.myapp = {
  serviceConfig = {
    EnvironmentFile = config.age.secrets.api-token.path;
  };
};
```

### Using Secrets in Home-Manager
```nix
# In home-manager configuration
programs.git = {
  enable = true;
  extraConfig = {
    credential.helper = "store --file=${config.age.secrets.github-token.path}";
  };
};

programs.ssh = {
  enable = true;
  includes = [ config.age.secrets.ssh-config.path ];
};
```

## Architecture

### Secret Lifecycle
```
Development/Source Machine
├─ Create plaintext secret in $EDITOR
├─ agenix encrypts with public keys
└─ .age file committed to git

Git Repository
└─ Encrypted .age files (safe to commit)

Target NixOS System
├─ NixOS activation
├─ agenix module decrypts secrets
│  └─ Uses SSH host private key
├─ Secrets mounted to /run/agenix/
└─ Services reference secret paths
```

### Module Integration
```
axios.lib.mkSystem
↓
Host Config (modules.secrets = true)
↓
NixOS Secrets Module
├─ Import agenix.nixosModules.default
├─ Configure identityPaths
├─ Auto-discover secrets from secretsDir (optional)
├─ Install agenix CLI
└─ Configure age.secrets

Home-Manager Integration
├─ Import agenix.homeManagerModules.default
├─ Configure user identityPaths
├─ Auto-discover user secrets (optional)
└─ Decrypt to ~/.config/agenix/
```

### Security Model
```
Encryption (Development Machine)
├─ Public keys from secrets.nix
├─ age encryption (modern, audited)
└─ Asymmetric encryption

Storage (Git Repository)
├─ Encrypted .age files only
├─ No plaintext secrets in git
└─ Safe to store in public repos

Decryption (Target System)
├─ SSH host private key (system secrets)
├─ SSH user private key (user secrets)
├─ Secrets only readable by specified owner/group
└─ Temporary mount at /run/agenix/ (tmpfs)
```

## Best Practices

### 1. Separate System and User Secrets
- **System secrets**: Database passwords, API keys, service credentials
- **User secrets**: GitHub tokens, SSH configs, personal credentials

### 2. Use Minimal Permissions
```nix
age.secrets.sensitive-key = {
  file = ./secrets/sensitive-key.age;
  mode = "400";    # Read-only for owner
  owner = "root";
  group = "root";
};
```

### 3. Public Keys in secrets.nix
- Keep all public keys in `secrets.nix`
- Version control this file
- Add new hosts/users by updating this file and re-keying

### 4. Rotate Secrets Regularly
```bash
# Update the secret content
agenix -e api-token.age

# Rebuild to apply
sudo nixos-rebuild switch --flake .
```

### 5. Backup Private Keys
- System host keys: `/etc/ssh/ssh_host_ed25519_key`
- User keys: `~/.ssh/id_ed25519`
- Without these, secrets cannot be decrypted!

### 6. Never Commit Private Keys or Plaintext Secrets
```gitignore
# .gitignore
secrets/*.key
secrets/plaintext/
*.pem
```

## Troubleshooting

### Secret Not Decrypting
```bash
# Check if secret file exists
ls -l /run/agenix/

# Check identity paths
age-keygen -y /etc/ssh/ssh_host_ed25519_key

# Verify public key in secrets.nix matches
cat secrets/secrets.nix | grep ssh-ed25519
```

### Permission Denied
```bash
# Check secret permissions
ls -l /run/agenix/my-secret

# Verify owner/group in configuration
nix eval .#nixosConfigurations.myhost.config.age.secrets.my-secret.owner
```

### agenix Command Not Found
```bash
# Ensure installCLI is enabled
secrets.installCLI = true;

# Rebuild
sudo nixos-rebuild switch --flake .
```

### Adding New Host
1. Get host's SSH public key:
```bash
ssh-keyscan myhost | ssh-keygen -lf -
# Or from the host:
cat /etc/ssh/ssh_host_ed25519_key.pub
```

2. Add to `secrets.nix`:
```nix
let
  newhost = "ssh-ed25519 AAAAC3... root@newhost";
in
{
  "secret.age".publicKeys = [ user1 system1 newhost ];
}
```

3. Re-key all secrets:
```bash
agenix --rekey
```

## Implementation Details

### Automatic Secret Discovery
When `secretsDir` is set, the module:
1. Reads all files in the directory using `builtins.readDir`
2. Filters for files ending in `.age`
3. Automatically creates `age.secrets` entries
4. Strips `.age` extension from secret names
5. Mounts decrypted secrets to `/run/agenix/<name>`

### Identity Path Resolution
The module tries SSH keys in order:
1. First key that exists is used for decryption
2. System: `/etc/ssh/ssh_host_ed25519_key` → `/etc/ssh/ssh_host_rsa_key`
3. User: `~/.ssh/id_ed25519` → `~/.ssh/id_rsa`

### Home-Manager Integration
- Secrets module automatically added to `home-manager.sharedModules`
- User secrets enabled by default when system secrets enabled
- Can be disabled per-user: `secrets.enable = false;`

## Files Changed/Created
```
New files:
+ modules/secrets/default.nix (system secrets module)
+ home/secrets/default.nix (home-manager secrets module)
+ docs/SECRETS_MODULE.md (this file)

Modified files:
~ flake.nix (added agenix input)
~ flake.lock (locked agenix)
~ home/default.nix (exported secrets module)
~ lib/default.nix (added secrets module support)
~ modules/default.nix (exported secrets module)
```

## Testing

### Initial Setup
```bash
# 1. Generate SSH keys if needed
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# 2. Get public keys
cat /etc/ssh/ssh_host_ed25519_key.pub
cat ~/.ssh/id_ed25519.pub

# 3. Create secrets.nix with public keys
mkdir secrets
cat > secrets/secrets.nix << 'EOF'
let
  user1 = "ssh-ed25519 AAAA... user@host";
  system1 = "ssh-ed25519 AAAA... root@host";
in
{
  "test-secret.age".publicKeys = [ user1 system1 ];
}
EOF

# 4. Create a test secret
agenix -e secrets/test-secret.age
# Enter some text in your editor and save

# 5. Enable in configuration
# Add modules.secrets = true to your host config
# Add secrets.secretsDir = ./secrets;

# 6. Rebuild
sudo nixos-rebuild switch --flake .

# 7. Verify secret decrypted
ls -l /run/agenix/
cat /run/agenix/test-secret
```

### Validation
```bash
# Check module enabled
nixos-option secrets.enable

# List secrets
ls -la /run/agenix/

# Check secret permissions
stat /run/agenix/test-secret

# Verify in services
systemctl cat myservice | grep -A5 EnvironmentFile
```

## Security Considerations

### ✅ Safe Practices
- Encrypted secrets in git repositories
- SSH key-based encryption/decryption
- Minimal file permissions (400-600)
- Secrets on tmpfs (`/run/agenix/`)
- No secrets in Nix store

### ⚠️ Important Notes
- **Private keys never in git**: SSH private keys must stay private
- **Public keys are public**: Safe to commit `secrets.nix` with public keys
- **Encrypted secrets are safe**: `.age` files can be in public repos
- **Host keys are critical**: Backup `/etc/ssh/ssh_host_*_key` files
- **User keys are personal**: Backup `~/.ssh/id_*` files

### 🔒 Threat Model
- **Protects against**: Secrets in Nix store, accidental leaks, git history
- **Does not protect against**: Root access on target system, compromised private keys
- **Assumes trusted**: Source machine, git repository server, SSH key security

## Comparison with Other Solutions

### agenix vs. sops-nix
| Feature | agenix | sops-nix |
|---------|--------|----------|
| Encryption | age (SSH keys) | Mozilla SOPS (GPG, age, etc.) |
| Complexity | Simple, minimal | More features, more complex |
| SSH Integration | Native | Via age backend |
| Key Management | SSH keys only | GPG, age, cloud KMS |
| axios Support | ✅ Integrated | ❌ Not integrated |

**Why agenix for axios:**
- Simpler for most use cases
- Reuses existing SSH infrastructure
- Minimal dependencies
- Clean integration with NixOS

## References
- [agenix GitHub](https://github.com/ryantm/agenix) - Age-encrypted secrets for NixOS
- [age](https://age-encryption.org/) - Modern encryption tool
- [NixOS Wiki: Agenix](https://nixos.wiki/wiki/Agenix) - Community documentation
- [Model Context Protocol](https://modelcontextprotocol.io) - For MCP server secrets

## Future Enhancements
- [ ] Integration with password managers (1Password, Bitwarden)
- [ ] Automatic secret rotation helpers
- [ ] Secret templates with variable substitution
- [ ] Vault backend support
- [ ] Hardware security module (HSM) integration
- [ ] Secret audit logging
- [ ] Multiple secrets directories
- [ ] Secret dependency validation

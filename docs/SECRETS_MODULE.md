# Secrets Module

## Overview
Manage encrypted secrets in your NixOS configuration using age encryption and SSH keys.

## Quick Start

### 1. Enable in Host Config
```nix
# In your hosts/yourhost.nix
modules = {
  secrets = true;
};

extraConfig = {
  secrets.secretsDir = ./secrets;  # Point to your secrets folder
};
```

### 2. Get Your Host's Public Key
```bash
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
# Example output: ssh-ed25519 AAAAC3Nza... root@yourhost
```

### 3. Create Your First Secret
```bash
# Create secrets directory
mkdir -p secrets

# Encrypt a secret (replace with your host public key)
echo "my-secret-password" | age -r "ssh-ed25519 AAAAC3Nza... root@yourhost" -o secrets/my-secret.age
```

### 4. Rebuild and Use
```bash
sudo nixos-rebuild switch --flake .

# Your secret is now available at:
cat /run/agenix/my-secret
# Outputs: my-secret-password
```

That's it! Any `.age` file in your secrets directory is automatically decrypted to `/run/agenix/<filename>`.


## Using Secrets in Your Config

### In NixOS Services
```nix
# Reference decrypted secrets by path
services.postgresql = {
  enable = true;
  passwordFile = "/run/agenix/database-password";
};

systemd.services.myapp = {
  serviceConfig = {
    EnvironmentFile = "/run/agenix/api-token";
  };
};
```

### In Home-Manager (User Secrets)
```nix
# In your home-manager config
secrets = {
  secretsDir = ./home-secrets;  # Separate folder for user secrets
};

# Secrets available at ~/.config/agenix/<name>
programs.git.extraConfig = {
  credential.helper = "store --file=~/.config/agenix/github-token";
};
```

## Advanced Usage

### Using the agenix CLI
The module installs the `agenix` CLI for easier secret management:

```bash
# Create secrets.nix with your public keys
cat > secrets/secrets.nix << 'EOF'
let
  host1 = "ssh-ed25519 AAAAC3... root@host1";
  user1 = "ssh-ed25519 AAAAC3... user@host";
in
{
  "my-secret.age".publicKeys = [ host1 user1 ];
  "api-token.age".publicKeys = [ host1 ];
}
EOF

# Edit/create secrets with your default editor
agenix -e secrets/my-secret.age
```

### Fine-Grained Control
For custom permissions and ownership:

```nix
# Instead of secrets.secretsDir, use age.secrets directly
age.secrets = {
  sensitive-key = {
    file = ./secrets/sensitive-key.age;
    mode = "400";
    owner = "myuser";
    group = "users";
  };
  
  shared-password = {
    file = ./secrets/shared-password.age;
    mode = "440";
    owner = "root";
    group = "networkmanager";
  };
};
```


## Multi-Host Setup

When you have multiple hosts that need the same secrets:

```nix
# secrets/secrets.nix
let
  # Get public keys from: sudo cat /etc/ssh/ssh_host_ed25519_key.pub
  laptop = "ssh-ed25519 AAAAC3... root@laptop";
  desktop = "ssh-ed25519 AAAAC3... root@desktop";
  server = "ssh-ed25519 AAAAC3... root@server";
in
{
  # Shared across all hosts
  "wifi-password.age".publicKeys = [ laptop desktop ];
  
  # Only on server
  "database-password.age".publicKeys = [ server ];
  
  # Server + desktop can access
  "api-key.age".publicKeys = [ desktop server ];
}
```

After updating `secrets.nix`, re-encrypt all secrets:
```bash
agenix --rekey
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `secrets.enable` | false | Enable secrets module |
| `secrets.secretsDir` | null | Auto-discover `.age` files from this directory |
| `secrets.installCLI` | true | Install agenix CLI tool |
| `secrets.identityPaths` | System SSH keys | Which private keys to use for decryption |


## Troubleshooting

### Secret not decrypting?
```bash
# Check if secret file exists
ls -l /run/agenix/

# Verify your host public key matches what's in secrets.nix
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
```

### Permission denied?
Check the secret's permissions and owner:
```bash
ls -l /run/agenix/my-secret

# If wrong, configure explicitly:
age.secrets.my-secret = {
  file = ./secrets/my-secret.age;
  owner = "myuser";
  mode = "400";
};
```

### Adding a new host?
1. Get the new host's public key: `sudo cat /etc/ssh/ssh_host_ed25519_key.pub`
2. Add it to `secrets/secrets.nix`
3. Re-encrypt: `agenix --rekey`

## Security Notes

- ✅ **Safe to commit**: `.age` encrypted files, `secrets.nix` (public keys)
- ❌ **Never commit**: Private keys, plaintext secrets
- 💾 **Backup**: SSH private keys (`/etc/ssh/ssh_host_*_key`) - without them you can't decrypt!

## References

- [agenix GitHub](https://github.com/ryantm/agenix) - The underlying tool
- [age-encryption.org](https://age-encryption.org/) - About age encryption

# Installation Guide

## Quick Installation

### Using .chezmoiexternal.toml (Recommended)

Add to your `.chezmoiexternal.toml`:

```toml
["scripts/sqlrsync-integration"]
    type = "archive"
    url = "https://github.com/pnwmatt/chezmoi-sqlrsync-integration/archive/main.tar.gz"
    exact = true
    stripComponents = 1
    refreshPeriod = "168h"
    include = ["scripts/**", "templates/**", "docs/**"]
```

### Manual Installation

```bash
# Clone to your chezmoi source directory
cd $(chezmoi source-path)
git clone https://github.com/pnwmatt/chezmoi-sqlrsync-integration.git temp-sqlrsync
cp -r temp-sqlrsync/scripts/* scripts/
cp -r temp-sqlrsync/templates/* templates/ 2>/dev/null || true
rm -rf temp-sqlrsync
```

### One-liner Installation

```bash
curl -sSL https://raw.githubusercontent.com/pnwmatt/chezmoi-sqlrsync-integration/main/install.sh | bash
```

## Configuration

### Basic Configuration

Add to your `.chezmoi.toml.tmpl`:

```toml
[data.sqlrsync]
  enabled = true
  install_method = "github"
  
  [[data.sqlrsync.databases]]
    name = "my-database"
    remote = "username/database.db"
    local_path = "~/.local/share/databases/database.db"
    sync_mode = "subscribe"
    subscribe_flags = "--waitIdle=10s"
    enabled = true
```

### Interactive Configuration

If you want interactive prompts during `chezmoi init`:

```toml
{{- $interactive := stdinIsATTY -}}
{{- $sqlrsyncEnabled := false -}}

{{- if hasKey . "sqlrsync" -}}
{{-   $sqlrsyncEnabled = .sqlrsync.enabled -}}
{{- else if $interactive -}}
{{-   $sqlrsyncEnabled = promptBool "Enable SQLRsync database synchronization" -}}
{{- end -}}

[data]
{{- if $sqlrsyncEnabled }}
  [data.sqlrsync]
    enabled = true
    # ... rest of configuration
{{- end }}
```

## Apply Configuration

```bash
# Apply the configuration
chezmoi apply

# Or with external refresh
chezmoi apply --refresh-externals
```

## Verification

### Check Installation
```bash
# Verify SQLRsync is installed
sqlrsync --version

# Check if services are running
systemctl --user list-units | grep sqlrsync
```


## Troubleshooting

### Common Issues

**Service not starting**
```bash
# Check service status
systemctl --user status sqlrsync-my-database-subscription

# Check service file
cat ~/.config/systemd/user/sqlrsync-my-database-subscription.service

# Reload systemd
systemctl --user daemon-reload
systemctl --user restart sqlrsync-my-database-subscription
```

**Permission issues**
```bash
# Check directories
ls -la ~/.local/share/databases/
ls -la ~/.config/systemd/user/

# Fix permissions
mkdir -p ~/.local/share/databases
chmod 755 ~/.local/share/databases
```
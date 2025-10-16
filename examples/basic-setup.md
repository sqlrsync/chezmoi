# Basic SQLRsync Setup

This example shows the simplest SQLRsync configuration for downloading and subscribing to a database.

## Configuration

Add to your `.chezmoi.toml.tmpl`:

```toml
[data.sqlrsync]
  enabled = true
  install_method = "github"
  version = "0.0.6"
  
  [[data.sqlrsync.databases]]
    name = "staggered-repetition"
    remote = "pnwmatt/staggered-repetition.db"
    local_path = "/myapps/staggered/staggered-repetition.db"
    sync_mode = "subscribe"
    subscribe_flags = "--waitIdle=10s"
    enabled = true
```

## What this does

1. **Installs SQLRsync** from GitHub releases
2. **Downloads** the database initially if it doesn't exist locally
3. **Subscribes** to real-time updates using websockets
4. **Places** the database in `/myapps/staggered/staggered-repetition.db`

## Usage

After running `chezmoi apply`, your database will be:
- Automatically downloaded on first run
- Kept in sync with real-time updates
- Available at `/myapps/staggered/staggered-repetition.db`

## Verification

Check that everything is working:

```bash
# Verify SQLRsync is installed
sqlrsync --version

# Check systemd service status
systemctl --user status sqlrsync-staggered-repetition-subscription

# View logs
journalctl --user -u sqlrsync-staggered-repetition-subscription -f
```
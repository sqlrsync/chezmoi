# Advanced Multi-Database Setup

This example shows how to configure multiple databases with different sync modes and schedules.

## Configuration

Add to your `.chezmoi.toml.tmpl`:

```toml
[data.sqlrsync]
  enabled = true
  install_method = "github"
  version = "0.0.6"
  
  # Learning database - real-time sync
  [[data.sqlrsync.databases]]
    name = "staggered-repetition"
    remote = "pnwmatt/staggered-repetition.db"
    local_path = "~/.local/share/databases/staggered-repetition.db"
    sync_mode = "subscribe"
    subscribe_flags = "--waitIdle=10s"
    enabled = true
  
  # Work database - pull-only, frequent updates
  [[data.sqlrsync.databases]]
    name = "work-references"
    remote = "company/shared-references.db"
    local_path = "~/.local/share/databases/work-refs.db"
    sync_mode = "cron:pull"
    pull_schedule = "hourly"
    enabled = true
  
  # Backup database - push-only, scheduled
  [[data.sqlrsync.databases]]
    name = "local-backup"
    remote = "pnwmatt/backups/laptop-data.db"
    local_path = "~/.local/share/app-data/important.db"
    sync_mode = "cron:push"
    push_schedule = "daily_2am"
    enabled = true
```

## Sync Modes Explained

### `subscribe` (Real-time bidirectional (or unidirectional if using a PULL key)
- Maintains persistent websocket connection
- Immediate updates when remote changes
- Best for: Active databases, learning apps, collaborative data

### `cron:pull` (Download-only)
- Only downloads updates from remote
- Good for: Reference data, read-only databases
- Scheduled updates based on `pull_schedule`

### `cron:push` (Push-only)
- Both uploads and downloads
- Configurable schedules for each direction
- Best for: Personal databases, backups, shared work

## Schedule Options

### Time-based Schedules
- `hourly` - Every hour
- `daily_6am` - Daily at 6:00 AM
- `daily_11pm` - Daily at 11:00 PM  
- `weekly_sat_9am` - Weekly on Saturday at 9:00 AM
- `weekly_sun_2am` - Weekly on Sunday at 2:00 AM

### Custom Cron
- `cron:0 */4 * * *` - Every 4 hours
- `cron:30 9,17 * * 1-5` - 9:30 AM and 5:30 PM, weekdays only


## Managing Services

### Check all SQLRsync services
```bash
systemctl --user list-units --type=service | grep sqlrsync
systemctl --user list-units --type=timer | grep sqlrsync
```

### View logs for specific database
```bash
# Real-time subscription logs
journalctl --user -u sqlrsync-staggered-repetition-subscription -f

# Scheduled pull logs
journalctl --user -u sqlrsync-personal-notes-pull -f

```
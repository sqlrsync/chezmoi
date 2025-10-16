# Configuration Reference

## SQLRsync Configuration Schema

### Top-level Configuration

```toml
[data.sqlrsync]
  enabled = true                    # Enable/disable SQLRsync integration
  install_method = "github"         # "github" or "manual"
  version = "0.0.6"                 # SQLRsync version to install
  install_dir = "/usr/local/bin"    # Installation directory
```

### Database Configuration

```toml
[[data.sqlrsync.databases]]
  name = "database-name"             # Unique identifier for this database
  remote = "username/database.db"    # Remote path (namespace/filename)
  local_path = "~/path/to/local.db"  # Local filesystem path
  sync_mode = "subscribe"            # Sync mode (see below)
  subscribe_flags = "--waitIdle=10s" # If subscribe mode, the flags necessary
  enabled = true                     # Enable this database
```

## Sync Modes

### `subscribe` - Real-time Sync
Maintains persistent websocket connection for immediate updates.

```toml
sync_mode = "subscribe"
# Uses real-time websockets to pull automatically after any push, and pushes depending
# on subscribe_flags values.
```

**Best for:**
- Interactive applications
- Frequently changing data
- Low-latency requirements

### `cron:pull` - Download Only
Only downloads updates from remote on schedule.

```toml
sync_mode = "cron:pull"
pull_schedule = "hourly"  # Required
# push_schedule ignored
```

**Best for:**
- Reference data
- Read-only databases
- Shared resources

## Schedule Formats

### Time-based Schedules

#### Hourly
```toml
pull_schedule = "hourly"  # Every hour at :00
```

#### Daily
```toml
pull_schedule = "daily_6am"   # 6:00 AM every day
push_schedule = "daily_11pm"  # 11:00 PM every day
```

#### Weekly
```toml
pull_schedule = "weekly_mon_9am"   # Monday at 9:00 AM
push_schedule = "weekly_sat_2pm"   # Saturday at 2:00 PM
pull_schedule = "weekly_sun_12am"  # Sunday at midnight
```

**Supported days:** `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`

#### Custom Cron
```toml
push_schedule = "cron:0 */4 * * *"      # Every 4 hours
pull_schedule = "cron:30 9,17 * * 1-5"  # 9:30 AM and 5:30 PM, weekdays
```

## Configuration Examples

### Learning Database (Bidirectional Real-time)
```toml
[[data.sqlrsync.databases]]
  name = "staggered-repetition"
  remote = "pnwmatt/staggered-repetition.db"
  local_path = "~/.local/share/databases/sr.db"
  sync_mode = "subscribe"
  subscribe_flags = "--waitIdle=10s"
  enabled = true
```

### Backup Database (Scheduled Push)
```toml
[[data.sqlrsync.databases]]
  name = "personal-backup"
  remote = "pnwmatt/backups/personal.db"
  local_path = "~/.local/share/personal/data.db"
  sync_mode = "cron:push"
  push_schedule = "daily_5pm"
  enabled = true
```

### Team Reference (Pull-only)
```toml
[[data.sqlrsync.databases]]
  name = "work-reference"
  remote = "company/shared-reference.db"
  local_path = "~/.local/share/work/reference.db"
  sync_mode = "pull_only"
  pull_schedule = "daily_8am"
  enabled = true
```

## Validation Rules

### Required Fields
- `name`: Must be unique across all databases
- `remote`: Must follow `namespace/filename.extension` format
- `local_path`: Must be valid filesystem path
- `sync_mode`: Must be one of `subscribe`, `cron:pull`, `cron:push`

### Optional Fields
- `push_schedule`: Only used with `cron:push` mode
- `pull_schedule`: Only used with `cron:pull` mode
- `enabled`: Defaults to `true`

### Schedule Validation
- File change schedules: Must match `file_change_(\d+)(m|h)` pattern
- Time schedules: Must use valid time format (12-hour with am/pm)
- Day names: Must be valid abbreviated day names
- Cron expressions: Standard cron format (5 fields)

## Systemd Service Names

Services are created with predictable names:

- **Subscription**: `sqlrsync-{name}-subscription.service`
- **Pull Timer**: `sqlrsync-{name}-pull.timer`
- **Push Timer**: `sqlrsync-{name}-push.timer`  

Where `{name}` is the database name from configuration.
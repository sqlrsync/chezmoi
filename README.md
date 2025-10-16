# Chezmoi SQLRsync Integration

A SQLRsync integration for Chezmoi that handles installation, database synchronization, and automated backup scheduling.

## Quick Start

Add to your `.chezmoi.toml.tmpl`:

```toml
[data.sqlrsync]
  enabled = true
  install_method = "github"  # "github", "manual"
  
  [[data.sqlrsync.databases]]
    name = "staggered-repetition"
    remote = "pnwmatt/staggered-repetition.db"
    local_path = "~/.local/share/databases/staggered-repetition.db"
    sync_mode = "subscribe"  # "subscribe", "pull_only", "push_pull"
    push_schedule = "file_change_5m"  # Push 5 min after file changes
    pull_schedule = "daily_6am"  # Pull daily at 6am
    enabled = true
```

Then run:
```bash
chezmoi apply
```

## Features

- ✅ **Automatic Installation**: Downloads and installs SQLRsync CLI
- ✅ **Smart Sync Modes**: Subscribe, pull-only, or bidirectional sync
- ✅ **Flexible Scheduling**: File-change triggers, cron-style, or real-time
- ✅ **Cross-platform**: Linux (systemd), macOS (launchd) support
- ✅ **Zero Downtime**: No database locks or service interruption
- ✅ **Version Control**: Time-travel and rollback capabilities

## Configuration Options

### Sync Modes
- `subscribe`: Real-time sync using websockets
- `pull_only`: Download-only mode
- `push_pull`: Bidirectional sync

### Schedule Formats
- `file_change_Xm`: Push X minutes after file changes
- `daily_Xam/Xpm`: Daily at specific time
- `weekly_X_Xam`: Weekly on day X at time X
- `hourly`: Every hour
- `cron:X X X X X`: Custom cron expression

## Examples

See `examples/` directory for complete configuration examples.

## License

MIT License - see LICENSE file.
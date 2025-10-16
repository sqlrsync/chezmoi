#!/bin/bash
# SQLRsync utilities for Chezmoi integration

set -euo pipefail

# Logging function
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} - $1" >&2
}

# Error handling
error_exit() {
    log_message "ERROR: $1"
    exit 1
}

# Setup database synchronization
setup_database_sync() {
    local db_name="$1"
    local remote_path="$2"
    local local_path="$3"
    local sync_mode="$4"
    local push_schedule="$5"
    local pull_schedule="$6"
    local subscribe_flags="$7"
    
    # Expand tilde in local path
    local_path="${local_path/#\~/$HOME}"
    local local_dir="$(dirname "$local_path")"
    
    log_message "Setting up sqlrsync for database: $db_name"
    log_message "  Remote: $remote_path"
    log_message "  Local: $local_path"
    log_message "  Mode: $sync_mode"
    
    # Create local directory
    mkdir -p "$local_dir"
    
    # Initial database pull if it doesn't exist
    if [[ ! -f "$local_path" ]]; then
        log_message "Performing initial pull of $db_name"
        if ! pull_database "$remote_path" "$local_path"; then
            log_message "Warning: Initial pull failed for $db_name - database may not exist remotely yet"
        fi
    fi
    
    # Setup sync based on mode
    case "$sync_mode" in
        "subscribe")
            setup_subscription "$db_name" "$local_path" "$remote_path" "$subscribe_flags"
            ;;
        "cron:pull")
            setup_pull_schedule "$db_name" "$remote_path" "$local_path" "$pull_schedule"
            ;;
        "cron:push")
            setup_push_schedule "$db_name" "$remote_path" "$local_path" "$push_schedule"
            ;;
        *)
            error_exit "Unknown sync mode: $sync_mode"
            ;;
    esac
    
    log_message "Database sync setup completed for: $db_name"
}

# Pull database from remote
pull_database() {
    local remote_path="$1"
    local local_path="$2"
    
    log_message "Pulling database: $remote_path -> $local_path"
    
    if ! sqlrsync "$remote_path" "$local_path"; then
        log_message "Failed to pull database from $remote_path"
        return 1
    fi
    
    return 0
}

# Push database to remote
push_database() {
    local local_path="$1"
    local remote_path="$2"
    
    log_message "Pushing database: $local_path -> $remote_path"
    
    if [[ ! -f "$local_path" ]]; then
        log_message "Local database not found: $local_path"
        return 1
    fi
    
    if ! sqlrsync "$local_path" "$remote_path"; then
        log_message "Failed to push database to $remote_path"
        return 1
    fi
    
    return 0
}

# Setup real-time subscription
setup_subscription() {
    local db_name="$1"
    local remote_path="$2"
    local local_path="$3"
    
    log_message "Setting up subscription for $db_name"
    
    # Create systemd service for subscription
    create_systemd_service "$db_name" "subscription" "sqlrsync \"$remote_path\" \"$local_path\" --subscribe $subscribe_flags"
    
    # Enable and start the service
    enable_systemd_service "sqlrsync-${db_name}-subscription"
}

# Setup pull schedule
setup_pull_schedule() {
    local db_name="$1"
    local remote_path="$2"
    local local_path="$3"
    local schedule="$4"
    
    if [[ -z "$schedule" ]]; then
        log_message "No pull schedule specified for $db_name"
        return 0
    fi
    
    log_message "Setting up pull schedule for $db_name: $schedule"
    
    # Create script for pulling
    local script_path="${HOME}/.local/bin/sqlrsync-pull-${db_name}.sh"
    mkdir -p "$(dirname "$script_path")"
    
    cat > "$script_path" << EOF
#!/bin/bash
set -euo pipefail
source "${HOME}/scripts/lib/sqlrsync_utils.sh" 2>/dev/null || true
log_message "Scheduled pull for $db_name"
pull_database "$remote_path" "$local_path"
EOF
    chmod +x "$script_path"
    
    # Create systemd timer
    create_systemd_timer "$db_name" "pull" "$script_path" "$schedule"
    enable_systemd_timer "sqlrsync-${db_name}-pull"
}

# Setup push schedule  
setup_push_schedule() {
    local db_name="$1"
    local remote_path="$2"
    local local_path="$3"
    local schedule="$4"
    
    if [[ -z "$schedule" ]]; then
        log_message "No push schedule specified for $db_name"
        return 0
    fi
    
    log_message "Setting up push schedule for $db_name: $schedule"
    
    if [[ "$schedule" =~ ^file_change_([0-9]+)m$ ]]; then
        # File change trigger
        local delay_minutes="${BASH_REMATCH[1]}"
        setup_file_watcher "$db_name" "$remote_path" "$local_path" "$delay_minutes"
    else
        # Regular schedule
        local script_path="${HOME}/.local/bin/sqlrsync-push-${db_name}.sh"
        mkdir -p "$(dirname "$script_path")"
        
        cat > "$script_path" << EOF
#!/bin/bash
set -euo pipefail
source "${HOME}/scripts/lib/sqlrsync_utils.sh" 2>/dev/null || true
log_message "Scheduled push for $db_name"
push_database "$local_path" "$remote_path"
EOF
        chmod +x "$script_path"
        
        create_systemd_timer "$db_name" "push" "$script_path" "$schedule"
        enable_systemd_timer "sqlrsync-${db_name}-push"
    fi
}

# Create systemd service
create_systemd_service() {
    local db_name="$1"
    local service_type="$2"
    local exec_command="$3"
    local service_name="sqlrsync-${db_name}-${service_type}"
    
    local service_file="${HOME}/.config/systemd/user/${service_name}.service"
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=SQLRsync ${service_type} for ${db_name}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${exec_command}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    
    log_message "Created systemd service: $service_name"
}

# Create systemd timer
create_systemd_timer() {
    local db_name="$1"
    local timer_type="$2"
    local script_path="$3"
    local schedule="$4"
    local service_name="sqlrsync-${db_name}-${timer_type}"
    
    # Create service file
    create_systemd_service "$db_name" "$timer_type" "$script_path"
    
    # Create timer file
    local timer_file="${HOME}/.config/systemd/user/${service_name}.timer"
    local on_calendar=$(parse_schedule_to_systemd "$schedule")
    
    cat > "$timer_file" << EOF
[Unit]
Description=SQLRsync ${timer_type} timer for ${db_name}
Requires=${service_name}.service

[Timer]
OnCalendar=${on_calendar}
Persistent=true
RandomizedDelaySec=60

[Install]
WantedBy=timers.target
EOF
    
    log_message "Created systemd timer: $service_name"
}

# Parse schedule string to systemd OnCalendar format
parse_schedule_to_systemd() {
    local schedule="$1"
    
    case "$schedule" in
        "hourly")
            echo "*:00:00"
            ;;
        "daily_"*"am"|"daily_"*"pm")
            local time_part="${schedule#daily_}"
            echo "*-*-* $(parse_time_to_24h "$time_part")"
            ;;
        "weekly_"*"_"*"am"|"weekly_"*"_"*"pm")
            local day_and_time="${schedule#weekly_}"
            local day="${day_and_time%%_*}"
            local time="${day_and_time#*_}"
            local systemd_day=$(parse_day_to_systemd "$day")
            echo "$systemd_day $(parse_time_to_24h "$time")"
            ;;
        "cron:"*)
            local cron_expr="${schedule#cron:}"
            # Convert cron to systemd (basic conversion)
            echo "$cron_expr"
            ;;
        *)
            log_message "Unknown schedule format: $schedule, using hourly"
            echo "*:00:00"
            ;;
    esac
}

# Convert time format to 24h
parse_time_to_24h() {
    local time="$1"
    
    if [[ "$time" =~ ^([0-9]{1,2})am$ ]]; then
        local hour="${BASH_REMATCH[1]}"
        if [[ "$hour" == "12" ]]; then hour="0"; fi
        printf "%02d:00:00" "$hour"
    elif [[ "$time" =~ ^([0-9]{1,2})pm$ ]]; then
        local hour="${BASH_REMATCH[1]}"
        if [[ "$hour" != "12" ]]; then hour=$((hour + 12)); fi
        printf "%02d:00:00" "$hour"
    else
        echo "$time"
    fi
}

# Convert day name to systemd format
parse_day_to_systemd() {
    case "$1" in
        "monday"|"mon") echo "Mon" ;;
        "tuesday"|"tue") echo "Tue" ;;
        "wednesday"|"wed") echo "Wed" ;;
        "thursday"|"thu") echo "Thu" ;;
        "friday"|"fri") echo "Fri" ;;
        "saturday"|"sat") echo "Sat" ;;
        "sunday"|"sun") echo "Sun" ;;
        *) echo "Mon" ;;
    esac
}

# Enable systemd service
enable_systemd_service() {
    local service_name="$1"
    
    if command -v systemctl &> /dev/null; then
        log_message "Enabling systemd service: $service_name"
        systemctl --user enable "$service_name" 2>/dev/null || true
        systemctl --user start "$service_name" 2>/dev/null || true
    fi
}

# Enable systemd timer
enable_systemd_timer() {
    local timer_name="$1"
    
    if command -v systemctl &> /dev/null; then
        log_message "Enabling systemd timer: $timer_name"
        systemctl --user enable "${timer_name}.timer" 2>/dev/null || true
        systemctl --user start "${timer_name}.timer" 2>/dev/null || true
    fi
}
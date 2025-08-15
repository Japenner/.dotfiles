# Snap - Local Backup & Sync Tool

A comprehensive backup and sync tool with intelligent retention policies, designed to keep your dotfiles, databases, notes, and important data safe with minimal effort.

## Features

- 🔄 **Incremental Backups**: Uses rsync for efficient, incremental backups
- 📅 **Retention Policies**: Configurable daily, weekly, and monthly retention
- 🎯 **Multiple Targets**: Support for local, remote, and cloud backup destinations
- 🗃️ **Database Backups**: Automated database dumps before file backups
- 📋 **Flexible Configuration**: YAML-based configuration with sensible defaults
- 🚀 **Restore Functionality**: Easy restoration from any snapshot
- 📊 **Status Reporting**: Detailed backup status and disk usage
- 🏃‍♂️ **Dry Run Mode**: Preview operations before execution
- 🔍 **Verbose Logging**: Detailed logs for troubleshooting

## Quick Start

1. **Initialize snap configuration**:

   ```bash
   snap init
   ```

2. **Create your first backup**:

   ```bash
   snap backup
   ```

3. **List your snapshots**:

   ```bash
   snap list
   ```

4. **Check backup status**:

   ```bash
   snap status
   ```

## Installation

1. Copy the `snap` script to your dotfiles bin directory:

   ```bash
   cp snap ~/.dotfiles/.local/bin/dev/
   chmod +x ~/.dotfiles/.local/bin/dev/snap
   ```

2. Make sure `~/.dotfiles/.local/bin/dev` is in your PATH:

   ```bash
   # Add to your .zshrc or .bashrc
   export PATH="$HOME/.dotfiles/.local/bin/dev:$PATH"
   ```

3. Install dependencies:

   ```bash
   # macOS with Homebrew
   brew install rsync

   # Ubuntu/Debian
   sudo apt install rsync

   # Most systems already have rsync installed
   ```

## Usage

### Basic Commands

```bash
# Initialize configuration
snap init

# Create a backup
snap backup

# List all snapshots
snap list

# Show backup status and disk usage
snap status

# Remove old snapshots based on retention policy
snap prune

# Restore from a specific snapshot
snap restore 2025-01-15_14-30-45

# Preview what would be done (dry run)
snap backup --dry-run
snap prune --dry-run
```

### Advanced Usage

```bash
# Backup to a specific target
snap backup -t external

# Custom retention period
snap backup -r 60  # Keep for 60 days

# Force operation without confirmation
snap restore 2025-01-15_14-30-45 -f

# Verbose output
snap backup -v

# Quiet mode (errors only)
snap backup -q
```

### Configuration Management

```bash
# View current configuration
snap config

# Edit configuration (opens in $EDITOR)
snap config edit
```

## Configuration

Snap uses a YAML configuration file located at `~/.config/snap/config.yaml`. The configuration is automatically created when you run `snap init`.

### Example Configuration

```yaml
# Snap Backup Configuration
version: 1

# Default settings
defaults:
  retention:
    daily: 30      # Keep daily backups for 30 days
    weekly: 8      # Keep weekly backups for 8 weeks
    monthly: 12    # Keep monthly backups for 12 months
  compression: true
  verbose: false

# Backup targets
targets:
  default:
    path: "~/Backups/snap/default"
    type: "local"
    enabled: true

  external:
    path: "/Volumes/Backup/snap"
    type: "local"
    enabled: true

  remote:
    path: "user@server:/backup/snap"
    type: "remote"
    enabled: false

# Backup sources
sources:
  dotfiles:
    path: "~/.dotfiles"
    enabled: true
    exclude:
      - ".git"
      - "*.log"
      - "node_modules"
      - ".DS_Store"

  config:
    path: "~/.config"
    enabled: true
    exclude:
      - "*/logs/*"
      - "*/cache/*"
      - "*/tmp/*"

  ssh:
    path: "~/.ssh"
    enabled: true
    exclude:
      - "known_hosts*"
      - "*.tmp"

  documents:
    path: "~/Documents"
    enabled: true
    exclude:
      - "*.tmp"
      - "*/cache/*"

  notes:
    path: "~/Notes"
    enabled: true
    exclude:
      - "*.tmp"
      - ".sync/*"

# Database backup commands (executed before file backup)
databases:
  postgres:
    command: "pg_dump -h localhost -U user database_name"
    output: "postgres_dump.sql"
    enabled: false

  mysql:
    command: "mysqldump -u user -p database_name"
    output: "mysql_dump.sql"
    enabled: false

# Custom scripts to run before/after backup
hooks:
  pre_backup:
    - "echo 'Starting backup...'"
  post_backup:
    - "echo 'Backup completed!'"
  pre_restore:
    - "echo 'Starting restore...'"
  post_restore:
    - "echo 'Restore completed!'"
```

## Environment Variables

Customize snap behavior with environment variables:

```bash
# Configuration and data directories
export SNAP_CONFIG_DIR="$HOME/.config/snap"
export SNAP_BACKUP_DIR="$HOME/Backups/snap"
export SNAP_LOG_DIR="$HOME/.config/snap/logs"

# Default retention policies
export SNAP_RETENTION_DAYS=30
export SNAP_RETENTION_WEEKLY=8
export SNAP_RETENTION_MONTHLY=12

# Default behavior
export SNAP_COMPRESSION=true
export SNAP_VERBOSE=false
export SNAP_DRY_RUN=false
```

## Backup Structure

Snapshots are organized by target and timestamp:

```text
~/Backups/snap/
├── default/
│   ├── 2025-01-15_14-30-45/
│   │   ├── .dotfiles/
│   │   ├── .config/
│   │   ├── .ssh/
│   │   ├── Documents/
│   │   ├── Notes/
│   │   └── .snap_meta
│   └── 2025-01-16_09-15-30/
│       └── ...
└── external/
    └── ...
```

### Snapshot Metadata

Each snapshot includes a `.snap_meta` file with information about the backup:

```bash
timestamp=2025-01-15_14-30-45
target=default
sources=~/.dotfiles ~/.config ~/.ssh ~/Documents ~/Notes
created_by=username
created_at=2025-01-15T14:30:45-08:00
snap_version=1.0.0
```

## Integration with Existing Tools

### Cron Automation

Add to your crontab for automated backups:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/snap backup -q

# Weekly pruning on Sundays at 3 AM
0 3 * * 0 /path/to/snap prune -q
```

### Git Hooks

Add to `.git/hooks/pre-push` for automatic backups before pushing:

```bash
#!/bin/bash
# Backup dotfiles before pushing
if [[ "$(pwd)" == "$HOME/.dotfiles" ]]; then
    snap backup -q -t git-backup
fi
```

### Aliases

Add convenient aliases to your shell configuration:

```bash
# Quick backup commands
alias backup="snap backup"
alias backup-status="snap status"
alias backup-list="snap list"
alias backup-prune="snap prune --dry-run"

# Restore helpers
alias restore-latest="snap list | tail -1 | awk '{print \$1}' | xargs snap restore"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the script is executable and you have write permissions to backup directories.
2. **rsync Errors**: Check that source directories exist and are readable.
3. **Disk Space**: Monitor backup directory size and adjust retention policies as needed.
4. **Remote Backups**: For remote targets, ensure SSH key authentication is set up.

### Logs

Backup logs are stored in `$SNAP_LOG_DIR` with detailed information about each operation:

```bash
# View recent backup log
ls -la ~/.config/snap/logs/
tail -f ~/.config/snap/logs/backup_*.log
```

### Debug Mode

Run with verbose output for troubleshooting:

```bash
snap backup -v  # Verbose output
snap status     # Check configuration and disk usage
```

## Advanced Features

### Multiple Targets

Configure multiple backup targets for redundancy:

```bash
# Backup to external drive
snap backup -t external

# Backup to remote server
snap backup -t remote
```

### Custom Retention Policies

Adjust retention policies per target or globally:

```bash
# Keep backups for 60 days
snap backup -r 60

# Custom weekly/monthly retention
snap backup --weekly 12 --monthly 24
```

### Database Integration

Snap can automatically backup databases before file backups. Configure database commands in the YAML configuration and they'll be executed and included in each snapshot.

## Security Considerations

- **SSH Keys**: `.ssh` directory is backed up by default. Ensure backup targets are secure.
- **Sensitive Files**: Use exclude patterns for sensitive files that shouldn't be backed up.
- **Remote Backups**: Use SSH key authentication for remote targets.
- **Encryption**: Consider encrypting backup targets for sensitive data.

## Contributing

This tool is part of a dotfiles setup and can be customized for your specific needs. Key areas for enhancement:

- YAML parsing (currently simplified)
- Cloud storage integration (AWS S3, Google Drive, etc.)
- Encryption support
- GUI interface
- Email notifications

## License

This tool is provided as-is for personal and educational use. Modify and distribute freely.

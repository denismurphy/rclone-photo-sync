# RClone Photo Sync

Syncing photos to an S3 bucket using RClone.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
- [Script Details](#script-details)
  - [photo_sync.sh (Bash)](#photo_syncsh-bash-script)
  - [photo_sync.ps1 (PowerShell)](#photo_syncps1-powershell-script)
- [Customisation](#customisation)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- rclone installed and configured with your S3 bucket
- Bash (for Unix-based systems) or PowerShell (for Windows)
- Appropriate permissions to access the source directory and create/modify files in the script directory

## Setup

1. Choose the appropriate script based on your operating system:
   - `photo_sync.sh` for Unix-based systems (Linux, macOS)
   - `photo_sync.ps1` for Windows

2. Edit the script to set the correct values for:
   - `SOURCE_DIR`: The directory containing your photos
   - `S3_BUCKET`: Your rclone remote configuration and S3 bucket path

3. Ensure the script has executable permissions (for Bash script):
   ```
   chmod +x photo_sync.sh
   ```

## Usage

Both scripts support the following commands:

- `start`: Begin the sync process
- `stop`: Stop the running sync process
- `restart`: Stop and then start the sync process
- `status`: Check if a sync process is currently running

### Bash Script (Unix-based systems)

```bash
./photo_sync.sh {start|stop|restart|status}
```

### PowerShell Script (Windows)

```powershell
.\photo_sync.ps1 {start|stop|restart|status}
```

## Script Details

### photo_sync.sh (Bash)

Key features:
- Uses rclone to sync photos to an S3 bucket
- Manages the sync process with start, stop, restart, and status functions
- Logs sync activities
- Handles graceful termination and force killing if necessary

### photo_sync.ps1 (PowerShell)

This script is designed for Windows systems. It uses PowerShell to manage the sync process.

Key features:
- Uses rclone to sync photos to an S3 bucket
- Manages the sync process with start, stop, restart, and status functions
- Logs sync activities
- Handles graceful termination and force killing if necessary

## Customization

You can customize the following variables in both scripts:

- `SOURCE_DIR`: Set this to the directory containing your photos
- `S3_BUCKET`: Set this to your rclone remote configuration and S3 bucket path
- Adjust rclone parameters in the `start_sync` function to fine-tune the sync process

## Troubleshooting

- If the sync doesn't start, check the log file (`photo_sync.log`) for error messages
- Ensure rclone is properly configured with your S3 bucket
- Verify that the source directory exists and is accessible
- Check that you have the necessary permissions to run the script and access the required directories
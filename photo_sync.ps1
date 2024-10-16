# Set variables

$SOURCE_DIR = "C:\Users\<username>\Pictures" # Typical pictures directory on Windows

# Example of S3 bucket path, the first part is rclone remote config you need to setup, S3 bucket name and path
# "S3-Photos-Config:my-s3-bucket/photos"
$S3_BUCKET = "<rclone-remote-config >:<s3-bucket-path>"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PID_FILE = Join-Path $SCRIPT_DIR "photo_sync.pid"
$LOG_FILE = Join-Path $SCRIPT_DIR "photo_sync.log"

# Function to start sync
function Start-Sync {
    if (Test-Path $PID_FILE) {
        Write-Host "A sync process is already running. Use 'stop' to end it first."
        exit 1
    }

    Write-Host "Starting sync process..."
    $rcloneArgs = @(
        "sync", $SOURCE_DIR, $S3_BUCKET,
        "-vv",
        "--progress",
        "--transfers", "4",
        "--checkers", "8",
        "--contimeout", "60s",
        "--timeout", "300s",
        "--retries", "3",
        "--low-level-retries", "10",
        "--stats", "10s",
        "--update",
        "--checksum",
        "--use-server-modtime",
        "--bwlimit", "0.28M",
        "--retries-sleep", "10s",
        "--log-file", $LOG_FILE
    )

    $process = Start-Process -FilePath "rclone" -ArgumentList $rcloneArgs -PassThru -WindowStyle Hidden

    if ($process) {
        $process.Id | Out-File -FilePath $PID_FILE
        Write-Host "Sync process started. PID: $($process.Id)"
    }
    else {
        Write-Host "Failed to start sync process. Check the log file for details."
        exit 1
    }
}

# Function to stop sync
function Stop-Sync {
    if (Test-Path $PID_FILE) {
        $PID = Get-Content $PID_FILE
        $process = Get-Process -Id $PID -ErrorAction SilentlyContinue

        if ($process) {
            Write-Host "Stopping sync process (PID: $PID)..."
            $process.CloseMainWindow() | Out-Null

            # Wait for up to 30 seconds for the process to terminate
            for ($i = 0; $i -lt 30; $i++) {
                if ($process.HasExited) {
                    Write-Host "Sync process stopped gracefully."
                    Remove-Item $PID_FILE
                    return
                }
                Start-Sleep -Seconds 1
            }

            # If process is still running after 30 seconds, force kill
            Write-Host "Sync process did not stop gracefully. Forcing termination..."
            Stop-Process -Id $PID -Force

            Start-Sleep -Seconds 1

            if (-not (Get-Process -Id $PID -ErrorAction SilentlyContinue)) {
                Write-Host "Sync process forcefully terminated."
                Remove-Item $PID_FILE
            }
            else {
                Write-Host "Failed to terminate sync process. Please check manually."
            }
        }
        else {
            Write-Host "No running sync process found."
            Remove-Item $PID_FILE
        }
    }
    else {
        Write-Host "No PID file found. Sync process is not running."
    }
}

# Function to check status
function Get-SyncStatus {
    if (Test-Path $PID_FILE) {
        $PID = Get-Content $PID_FILE
        $process = Get-Process -Id $PID -ErrorAction SilentlyContinue

        if ($process) {
            Write-Host "Sync process is running. PID: $PID"
        }
        else {
            Write-Host "PID file exists, but process is not running. Cleaning up..."
            Remove-Item $PID_FILE
        }
    }
    else {
        Write-Host "No active sync process found."
    }
}

# Main script logic
switch ($args[0]) {
    "start" { Start-Sync }
    "stop" { Stop-Sync }
    "restart" {
        Stop-Sync
        Start-Sleep -Seconds 2
        Start-Sync
    }
    "status" { Get-SyncStatus }
    default {
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) {start|stop|restart|status}"
        exit 1
    }
}

exit 0
#!/bin/bash

# Set variables

#SOURCE_DIR="/Users/<username>/Pictures/Photos Library.photoslibrary" # Typical pictures directory on macOS
SOURCE_DIR=" /home/<username>/Pictures" # Typical pictures directory on Linux

# Example of S3 bucket path, the first part is rclone remote config you need to setup, S3 bucket name and path
# "S3-Photos-Config:my-s3-bucket/photos"
S3_BUCKET = "<rclone-remote-config >:<s3-bucket-path>"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PID_FILE="$SCRIPT_DIR/photo_sync.pid"
LOG_FILE="$SCRIPT_DIR/photo_sync.log"

# Function to start sync
start_sync() {
    if [ -f "$PID_FILE" ]; then
        echo "A sync process is already running. Use 'stop' to end it first."
        exit 1
    fi

    echo "Starting sync process..."
    rclone sync "$SOURCE_DIR" "$S3_BUCKET" \
        -vv \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --timeout 300s \
        --retries 3 \
        --low-level-retries 10 \
        --stats 10s \
        --exclude ".DS_Store" \
        --exclude "*.photoslibrary/private/com.apple.photoanalysisd/**" \
        --update \
        --checksum \
        --use-server-modtime \
        --bwlimit 0.28M \
        --retries-sleep 10s \
        --log-file "$LOG_FILE" > /dev/null 2>&1 &
    
    PID=$!
    if ps -p $PID > /dev/null; then
        echo $PID > "$PID_FILE"
        echo "Sync process started. PID: $PID"
    else
        echo "Failed to start sync process. Check the log file for details."
        exit 1
    fi
}

# Function to stop sync
stop_sync() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            echo "Stopping sync process (PID: $PID)..."
            kill $PID
            
            # Wait for up to 30 seconds for the process to terminate
            for i in {1..30}; do
                if ! ps -p $PID > /dev/null; then
                    echo "Sync process stopped gracefully."
                    rm "$PID_FILE"
                    return 0
                fi
                sleep 1
            done
            
            # If process is still running after 30 seconds, force kill
            echo "Sync process did not stop gracefully. Forcing termination..."
            kill -9 $PID
            sleep 1
            
            if ! ps -p $PID > /dev/null; then
                echo "Sync process forcefully terminated."
                rm "$PID_FILE"
            else
                echo "Failed to terminate sync process. Please check manually."
                return 1
            fi
        else
            echo "No running sync process found."
            rm "$PID_FILE"
        fi
    else
        echo "No PID file found. Sync process is not running."
    fi
}

# Function to check status
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            echo "Sync process is running. PID: $PID"
        else
            echo "PID file exists, but process is not running. Cleaning up..."
            rm "$PID_FILE"
        fi
    else
        echo "No active sync process found."
    fi
}

# Main script logic
case "$1" in
    start)
        start_sync
        ;;
    stop)
        stop_sync
        ;;
    restart)
        stop_sync
        sleep 2
        start_sync
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
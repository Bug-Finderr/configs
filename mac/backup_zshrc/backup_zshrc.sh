#!/bin/bash

ZSHRC_PATH="$HOME/.zshrc"
BACKUP_DIR="$HOME/Dev/tweaks/backup_zshrc/actual_backups"
LOG_FILE="$HOME/Dev/tweaks/backup_zshrc/backup.log"
MAX_BACKUPS=10
MAX_LOG_LINES=100

mkdir -p "$BACKUP_DIR"

truncate_log() {
    if [ "$(wc -l < "$LOG_FILE")" -gt "$MAX_LOG_LINES" ]; then
        tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

create_backup() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/zshrc_backup_$TIMESTAMP"

    if cp "$ZSHRC_PATH" "$BACKUP_FILE"; then
        echo "Backup created: $BACKUP_FILE" >> "$LOG_FILE"
    else
        echo "Error creating backup: $BACKUP_FILE" >> "$LOG_FILE"
        return 1
    fi

    # Remove old backups if exceeding MAX_BACKUPS
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" 2>/dev/null | tail -1)
        if rm "$BACKUP_DIR/$OLDEST_BACKUP"; then
            echo "Old backup removed: $OLDEST_BACKUP" >> "$LOG_FILE"
        else
            echo "Error removing old backup: $OLDEST_BACKUP" >> "$LOG_FILE"
        fi
    fi

    truncate_log
}

echo "Monitoring $ZSHRC_PATH for changes..." >> "$LOG_FILE"
/opt/homebrew/bin/fswatch -o "$ZSHRC_PATH" | while read -r; do
    create_backup || echo "create_backup failed" >> "$LOG_FILE"
done

# Backup .zshrc

This script automatically creates backups of your `.zshrc` file whenever it changes.

## Features

- Monitors the `.zshrc` file for changes.
- Automatically creates timestamped backups.
- Keeps the most recent 10 (configuarble) backups and removes older ones.
- Limits the log file to the most recent 100 lines to prevent it from growing indefinitely.

## Setup

1. **Clone or download this repository** to your desired location.

2. **Install dependencies**:
   - Ensure `fswatch` is installed:

     ```zsh
     brew install fswatch
     ```

3. **Configure the backup directory**:
   - Open the `backup_zshrc.sh` script in any text editor:

     ```zsh
     vim /path/to/backup_zshrc.sh
     ```

   - Modify the `BACKUP_DIR` variable to specify where you want the backups to be stored. For example:

     ```zsh
     BACKUP_DIR="$HOME/my_custom_backup_directory"
     ```

   - Save and close the file.

4. **Update the `plist` file path if needed**:
   - If you moved the `backup_zshrc.sh` script to a different location, update the path in the `com.user.backupzshrc.plist` file:

     ```xml
     <key>ProgramArguments</key>
     <array>
         <string>/path/to/backup_zshrc.sh</string>
     </array>
     ```

   - Save the updated `plist` file.

5. **Set up the launch agent**:
   - Copy the `com.user.backupzshrc.plist` file to `~/Library/LaunchAgents/`:

     ```zsh
     cp com.user.backupzshrc.plist ~/Library/LaunchAgents/
     ```

   - Load the launch agent:

     ```zsh
     launchctl load ~/Library/LaunchAgents/com.user.backupzshrc.plist
     ```

6. **Verify the setup**:
   - Check if the launch agent is running:

     ```zsh
     launchctl list | grep com.user.backupzshrc
     ```

## How It Works

- The script monitors your `.zshrc` file for changes using `fswatch`.
- When a change is detected, it creates a backup in the `actual_backups/` directory with a timestamp.
- If the number of backups exceeds 10, the oldest backup is automatically deleted.
- The log file (`backup.log`) is limited to the most recent 100 lines to prevent it from growing indefinitely.

## Backup Location

Backups are stored in the `actual_backups/` directory within this project.

## Uninstallation

To stop the backup process and remove the setup:

1. Unload the launch agent:

   ```zsh
   launchctl unload ~/Library/LaunchAgents/com.user.backupzshrc.plist
   ```

2. Remove the launch agent file:

   ```zsh
   rm ~/Library/LaunchAgents/com.user.backupzshrc.plist
   ```

3. Delete this project directory if no longer needed.

## Notes

- Ensure that your `.zshrc` file exists at `$HOME/.zshrc`.
- Modify the backup_zshrc.sh script if you want to customize the backup directory or the number of backups to keep.

## Authors

[Bug-Finderr](https://github.com/Bug-Finderr)

## License

This project is open-source and free to use.

Open to contributions!

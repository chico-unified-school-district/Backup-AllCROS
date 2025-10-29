# Backup-AllCROS

Purpose

- Export Chrome OS device data using GAM, compress the export, and move it to a remote file share for archival and rotation.

Prerequisites

- PowerShell 5.0 or newer.
- GAM installed and configured (script expects gam.exe at `C:\GAM7\gam.exe`).
- 7-Zip command line (7za.exe) available in the script's `.\lib\` folder.
- A network share with write access for the backup destination.
- An account with permission to write to the share (use a PSCredential object).

Files

- Backup-AllCROS.PS1 — main script.
- lib\7za.exe — compressor used by the script.
- README.MD — this file.

Basic usage

- Run interactively:
  - $cred = Get-Credential
  - .\Backup-AllCROS.PS1 -BackupRoot "\\SERVER\Share" -ShareCred $cred
- Dry run (no GAM call; returns test entries):
  - .\Backup-AllCROS.PS1 -BackupRoot "\\SERVER\Share" -ShareCred $cred -WhatIf

Parameters

- -BackupRoot (string, mandatory): UNC path to destination share (e.g. \\server\backups).
- -ShareCred (PSCredential, mandatory): Credential object with access to the share.
- -WhatIf (switch): Use to run a lightweight test (script simulates device output).

Behavior highlights

- Creates a temporary folder `. \BackupTemp` in the script's working directory for intermediate files.
- Calls GAM to export Chrome OS device data (full export) to a CSV file.
- Compresses the CSV using 7za to a timestamped ZIP archive.
- Maps a temporary PSDrive named `Backup:` to the provided UNC share and moves the ZIP there.
- Retains backups for 30 days (removes older .zip and .csv files from both local and remote locations if accessible).
- Cleans up temporary local files and removes the PSDrive when done.

Scheduling

- Create a scheduled task running PowerShell with highest privileges and using an account that has access to the share.
- Example action:
  - Program/script: powershell.exe
  - Arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\Backup-AllCROS.PS1" -BackupRoot "\\SERVER\Share" -ShareCred (the task should run under an account so a credential object is not required interactively)
- Alternatively run a wrapper script that builds a PSCredential from a secure vault.

Troubleshooting

- "New-PSSdrive" errors: avoid adding a trailing backslash to the UNC path when passing -BackupRoot.
- Permission denied moving file: verify the account in -ShareCred has write permissions on the share.
- GAM failures: confirm `C:\GAM7\gam.exe` exists and is properly authorized.
- 7za errors: confirm `.\lib\7za.exe` is present and executable from the script folder.
- Verify scheduled task uses an account with network access to the share (local system may not have access to network shares).

Security notes

- Do not store plaintext passwords in scripts. Use PSCredential objects built at runtime or secrets from a secure vault.
- Consider using a managed service account or machine account with least privilege.

Contact / Maintenance

- Update GAM and 7za binaries periodically.
- Adjust retention period by editing the script's AddDays(-30) value if needed.

License

- Internal use; adapt as needed for your environment.

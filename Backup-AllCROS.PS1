#Requires -Version 5.0
<# 
.SYNOPSIS
 Dumps all Chrome OS device data into a text file, compresses the file, and moves it to a remote server
.DESCRIPTION
.EXAMPLE
 Backup-AllCROS.ps1 -BackupRoot "\\ServerName\Share" -ShareCred $CredentialObject
.EXAMPLE
 Backup-AllCROS.ps1 -BackupRoot "\\ServerName\Share" -ShareCred $CredentialObject -WhatIf
.INPUTS
 Server Share UNC Path
 Account with access to the Server Share
.OUTPUTS
 ZIP Archives
.NOTES
#>

[cmdletbinding()]
param (
 [Parameter(Position = 0, Mandatory = $True)]
 [string]$BackupRoot,
 [Parameter(Position = 1, Mandatory = $True)]
 [System.Management.Automation.PSCredential]$ShareCred,
 [switch]$WhatIf
)

# CLS; $error.clear() # Clear Screen and $error
Get-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 4096
Get-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB

# Variables
$ENV:GAM_DEVICE_MAX_RESULTS = 100
$driveName = "Backup"

# Processing
Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue | Remove-PSDrive
"Adding a trailing \ to the $BackupRoot will cause New-PSSdrive to error."
"Connecting to $BackupRoot with $($ShareCred.Username)"
New-PSDrive -Name $driveName -PSProvider FileSystem -Root $BackupRoot -Credential $ShareCred -ErrorAction SilentlyContinue > $null

if ( (Test-Path -Path .\BackupTemp) -eq $false ) { New-Item -Name BackupTemp -ItemType Directory }
if ( (Test-Path "$DriveName`:") -eq $false ) { "[WARNING] $BackupRoot not available" }

($backUpTempFileName = "CROS-BACKUP-$(Get-Date -f yyyy-MM-dd-mmss).csv")
$backupFilePath = ".\BackupTemp\$backUpTempFileName"

if ($WhatIf) { $allCros = 10..1 } 
else {
 "Retrieving all CRoS devices..."
 ($allCros = .\lib\gam-64\gam.exe print cros allfields) *>$null # *>$null Suppresses gam.exe output.
}

"Exporting allCros to $backupFilePath"
$allCros | Out-File $backupFilePath

'Clearing allCros variable'
$allCros = $null

$archiveName = "CROS-Backup-$(Get-Date -f yyyy-MM-dd-mmss).zip"
"Compressing $backupFilePath to $archiveName"
Compress-Archive -Path $backupFilePath -DestinationPath ".\BackupTemp\$archiveName" -CompressionLevel Optimal

if (Test-Path "$DriveName`:") {
 "Moving $backupFilePath to $BackupRoot"
 Move-Item -Path ".\BackupTemp\$archiveName" -Destination "$DriveName`:"
}
else { "[WARNING] Archive not moved. $BackupRoot not available." }

"Removing $backupFilePath..."
Remove-Item -Path $backupFilePath -Force -Confirm:$false

if (Test-Path "$DriveName`:") { $BackupFolders = ".\BackupTemp", "$driveName`:" }
else { $BackupFolders = ".\BackupTemp" }
"Removing old backup .zip and .csv files..."
$deleteOlderThanDate = (Get-Date).AddDays(-30)
$oldBackups = Get-ChildItem $BackupFolders | Where-Object { ($_.LastWriteTime -le $deleteOlderThanDate) -and 
 ( ($_.name -like "*.zip") -or ($_.name -like "*.csv") ) }
$oldBackups | Remove-Item -Force -Confirm:$false

if (Test-Path "$DriveName`:") {
 "Removing PSDrive '$driveName'..."
 Remove-PSDrive -Name $driveName -Confirm:$false
}
#Requires -Version 5.0
<#
.SYNOPSIS
 Dumps all Chrome OS device data into a text file, compresses the file, and moves it to a remote server
.DESCRIPTION
This might need to be retired as Google would have to colapse for this data to everr be used.
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

# Variables
$driveName = 'Backup'

# Processing
Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue | Remove-PSDrive
"Adding a trailing \ to the $BackupRoot will cause New-PSSdrive to error."
"Connecting to $BackupRoot with $($ShareCred.Username)"
New-PSDrive -Name $driveName -PSProvider FileSystem -Root $BackupRoot -Credential $ShareCred -ErrorAction SilentlyContinue > $null

if ($WhatIf) { $allCros = 10..1 }
else {
 'Retrieving all CRoS devices...'
 try { ($allCros = C:\GAM7\gam.exe print cros allfields) *>$null }
 catch { Write-Error "Error retrieving CROS devices: $_"; $($_.Exception.Message) }
}

'CrOS Results: {0}' -f $allCros.count

'Checking local backup directory'
if ( (Test-Path -Path .\BackupTemp) -eq $false ) { New-Item -Name BackupTemp -ItemType Directory }
if ( (Test-Path "$DriveName`:") -eq $false ) { "[WARNING] $BackupRoot not available" }

'Setting local backup csv file name and path'
($backUpCSVFileName = "CROS-BACKUP-$(Get-Date -f yyyy-MM-dd-mmss).csv")
$localBackupCSVFilePath = ".\BackupTemp\$backUpCSVFileName"

"Exporting allCros to $localBackupCSVFilePath"
$allCros | Out-File $localBackupCSVFilePath

'Clearing allCros variable'
$allCros = $null

$archiveName = "CROS-Backup-$(Get-Date -f yyyy-MM-dd-mmss).zip"
$localArchiveZipFilePath = ".\BackupTemp\$archiveName"
"Compressing $localBackupCSVFilePath to $localArchiveZipFilePath"

.\lib\7za.exe a -mx=9 $localArchiveZipFilePath $localBackupCSVFilePath
# Compress-Archive -Path $backupFilePath -DestinationPath ".\BackupTemp\$archiveName" -CompressionLevel Optimal

if (Test-Path "$DriveName`:") {
 "Moving $localArchiveZipFilePath to $BackupRoot `($DriveName`:`)"
 Move-Item -Path $localArchiveZipFilePath -Destination "$DriveName`:"
}
else { "[WARNING] Archive not moved. $BackupRoot not available." }

'Removing local backup files...'
Remove-Item -Path $localBackupCSVFilePath -Force -Confirm:$false

if (Test-Path "$DriveName`:") { $BackupFolders = '.\BackupTemp', "$driveName`:" }
else { $BackupFolders = '.\BackupTemp' }
'Removing old backup .zip and .csv files...'
$deleteOlderThanDate = (Get-Date).AddDays(-30)
$oldBackups = Get-ChildItem $BackupFolders | Where-Object { ($_.LastWriteTime -le $deleteOlderThanDate) -and
 ( ($_.name -like '*.zip') -or ($_.name -like '*.csv') ) }
$oldBackups | Remove-Item -Force -Confirm:$false

if (Test-Path "$DriveName`:") {
 "Removing PSDrive '$driveName'..."
 Remove-PSDrive -Name $driveName -Confirm:$false
}
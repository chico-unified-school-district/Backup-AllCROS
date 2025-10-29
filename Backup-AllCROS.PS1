<#
.SYNOPSIS
 Dumps all active Chrome OS device data into a text file, compresses the file, and stores it locally for 30 days.
.DESCRIPTION
This might need to be retired as Google would have to collapse for this data to ever be used.
.EXAMPLE
 Backup-AllCROS.ps1
.INPUTS
 Server Share UNC Path
 Account with access to the Server Share
.OUTPUTS
 ZIP Archives
.NOTES
#>

[cmdletbinding()]
param (
 [switch]$WhatIf
)

function Get-CrosDevices {
 begin {
  $ErrorActionPreference = 'Continue'
  $fields = @(
   'deviceId'
   'serialNumber'
   'macAddress'
   'status'
   'model'
   'orgUnitPath'
   'osUpdateStatus'
   'osVersion'
   'recentUsers'
   'firmwareVersion'
   'deviceLicenseType'
  )
 }
 process {
  Write-Host ('{0},{1}' -f $MyInvocation.MyCommand.Name, (Get-Date)) -F Green
  # ($activeCros = C:\GAM7\gam.exe info cros ac425222-6796-4709-b33a-d473c87c7e4b fields $fields) *> $null
  ($activeCros = C:\GAM7\gam.exe print cros query 'status:ACTIVE' fields $fields) 2>$null
  'CrOS Results: {0}' -f @($activeCros).count
  $activeCros
 }
 end {
  $ErrorActionPreference = 'Stop'
 }
}

# ================================ Main Script ================================
Import-Module -Name CommonScriptFunctions -Cmdlet Show-BlockInfo

$fullCsvPath = ".\data\CROS-ALL-$(Get-Date -f yyyy-MM-dd-mmss).csv"
Write-Host "Exporting data to $fullCsvPath" -F Blue
Get-CrosDevices | Out-File $fullCsvPath

$fullZipPath = ".\data\CROS-ALL-$(Get-Date -f yyyy-MM-dd-mmss).zip"
Write-Host "Compressing $fullCsvPath to $fullZipPath" -F Magenta
Compress-Archive -Path $fullCsvPath -DestinationPath $fullZipPath -CompressionLevel Optimal

Write-Host "Removed local csv file $fullCsvPath" -F yellow
Remove-Item -Path $fullCsvPath -Confirm:$false

Write-Host 'Removing old backup .zip and .csv files...' -F Cyan
$deleteOlderThanDate = (Get-Date).AddDays(-30)
$oldBackups = Get-ChildItem $BackupFolders | Where-Object { ($_.LastWriteTime -le $deleteOlderThanDate) -and
 ( ($_.name -like '*.zip') -or ($_.name -like '*.csv') ) }
$oldBackups | Remove-Item -Force -Confirm:$false

Write-Host ('{0},{1},Script End' -f $MyInvocation.MyCommand.Name, (Get-Date)) -F Green
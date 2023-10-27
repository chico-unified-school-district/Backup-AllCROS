$params = @{
 BackUpRoot = '\\CHASE.CHICO.USD\ALLCROS_BACKUP'
 ShareCred  = $ADTasks
}
$params
ls -recurse -filter *.ps1 | Unblock-File
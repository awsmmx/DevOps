$scriptPath = "Path\Name.ps1"
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
 -Argument "-executionpolicy bypass -noprofile -file $scriptPath"

$trigger =  New-ScheduledTaskTrigger -AtLogOn #-Daily -At 11:43pm

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "TaskName" -Description "Description" | Out-Null
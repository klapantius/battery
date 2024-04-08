# Prototype to schedule the battery-charger script as a scheduled task
# Credits to https://sid-500.com/2022/08/17/how-to-include-your-powershell-7-scripts-in-task-scheduler/

$Action = New-ScheduledTaskAction -Execute "pwsh –Noprofile -WindowStyle Hidden -ExecutionPolicy Bypass -File $PSScriptRoot\onoff.ps1"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
$Principal = New-ScheduledTaskPrincipal -UserId ad005\z001rybj
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal

Register-ScheduledTask -TaskName "battery-onoff" -InputObject $Task -Force
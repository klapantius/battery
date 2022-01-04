[cmdletbinding()]
param(
  [bool]$force = $false,
  [int]$lowerTreshold = 30, #22
  [int]$upperTreshold = 80, #82
  [int]$iterationDelay = 0,
  [switch]$terminate
)

Import-Module '.\onoff-functions.ps1' -force

function Start-Once {
  write-log ">>>>> Start-Once"
  launch -force $force -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
  write-log "----- Start-Once completed"
}

$job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
if ($null -ne $job -and ($iterationDelay -gt 0 -or $terminate.IsPresent)) {
  write-log "stopping earlier job ""$($job.Name) $($job.Id)"""
  Stop-Job -Name $jobName -ErrorAction SilentlyContinue
  Remove-Job -Name $jobName -ErrorAction SilentlyContinue
  if ($terminate.IsPresent) {
    write-log "script is done, it has just terminated a pending job"
    return 
  }
  write-log "continuing after the clean-up sequence"
}

if ($iterationDelay -gt 0) {
  do {
    write-log "new iteration starts"
    Start-Once
    Start-Sleep -Seconds $(60 * $iterationDelay)
  } while ($true) 
}
else { Start-Once }
[cmdletbinding()]
param(
  [bool]$force = $false,
  [int]$lowerTreshold = 30, #22
  [int]$upperTreshold = 80, #82
  [int]$iterationDelay = 0,
  [switch]$LogToConsole
)

. "$PSScriptRoot\onoff-functions.ps1" -force # load first

function Start-Once {
  . "$PSScriptRoot\onoff-functions.ps1" -force # reload every time to ensure latest design
  launch -force $force -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
}

write-log "-------- $(Get-Date -Format "MM.dd HH:mm") --------"
if ($iterationDelay -gt 0) {
  do {
    write-log "new iteration starts"
    Start-Once
    Start-Sleep -Seconds $(60 * $iterationDelay)
  } while ($true) 
}
else { 
  write-log "single execution starts"
  Start-Once 
}
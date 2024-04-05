$triggerFolder = 'g:\My Drive\iktato\laptop';

. .\logging.ps1
. .\battery.ps1
. .\trigger.ps1

function evaluate {
  param(
    [bool]$force = $false,
    [int]$proc,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  if ($force) {
    write-log "evaluate: force ==> true"
    return $true 
  }
  if (($proc -lt $lowerTreshold) -or ($upperTreshold -lt $proc)) {
    write-log "a limit has been exceeded"
    $lastProc = get-lastTrigger | get-level
    if ($lastProc -ge 0) {
      write-log "last trigger created at $lastProc%"
      if ($lastProc -le $proc -and $proc -lt $lowerTreshold) {
        write-log "already triggered (on) and charging"
        return $false
      }
      if ($upperTreshold -lt $proc -and $proc -le $lastProc) {
        write-log "already triggered (off) and depleting"
        return $false
      }
      # todo: show an error if current level is further out than the last trigger
      write-log "trigger comparision allows to continue"
    }
    write-log "evaluate: true"
    return $true
  }
  write-log "evaluate: no limit violation detected ==> false"
  return $false
}

function trigger-ifttt {
  param(
    [parameter(ValueFromPipeline)]
    [switch]$armed
  )
  if ($armed) { place_a_trigger_file }
  return $armed
}  

function launch {
  param(
    [bool]$force = $false,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  $proc = get-batteryLevel
  write-log "current level is $proc%"
  if (evaluate -force $force -proc $proc -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt) {
    compose-message -proc $proc -force $force | show-notification
  }
}
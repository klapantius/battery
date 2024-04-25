. "$PSScriptRoot\logging.ps1"
. "$PSScriptRoot\battery.ps1"
. "$PSScriptRoot\trigger.ps1"

function evaluate {
  param(
    [bool]$force = $false,
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  if ($force) {
    write-log "evaluate: force ==> true"
    return $true 
  }
  if (($currentLevel -lt $lowerTreshold) -or ($upperTreshold -lt $currentLevel)) {
    write-log "a limit has been exceeded"
    $lastTrigger = get-lastTrigger
    $lastLevel = $lastTrigger | get-level
    if ($lastLevel -ge 0) {
      $supposedDurationToGetIntoInnerTresholdRange = 30 # minutes
      $lastTriggerTime = get-lastTriggerTime
      $lastTriggerAssumedToBeInvalid = -not ((Get-Date) -gt $lastTriggerTime.AddMinutes($supposedDurationToGetIntoInnerTresholdRange))
      write-log "it is $(Get-Date -Format 'HH:mm'); last trigger: $lastTrigger --> $lastLevel% at $lastTriggerTime; validity treshold: $supposedDurationToGetIntoInnerTresholdRange ==> lastTriggerAssumedToBeInvalid: $lastTriggerAssumedToBeInvalid"
      if ($lastTriggerAssumedToBeInvalid) {
        return $true
      }
      if ($lastLevel -le $currentLevel -and $currentLevel -lt $lowerTreshold) {
        write-log "already triggered (on) and charging"
        return $false
      }
      if ($upperTreshold -lt $currentLevel -and $currentLevel -le $lastLevel) {
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
  if ($armed) {
    place_a_trigger_file 
    synchronise-trigger
  }
  return $armed
}

function launch {
  param(
    [bool]$force = $false,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  $currentLevel = get-batteryLevel
  write-log "current level is $currentLevel%"
  if (evaluate -force $force -proc $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt) {
    compose-message -proc $currentLevel -force $force | show-notification
  }
}
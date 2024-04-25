. "$PSScriptRoot\logging.ps1"
. "$PSScriptRoot\battery.ps1"
. "$PSScriptRoot\trigger.ps1"

function get-violation{
  param(
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  write-log (("$currentLevel", "$lowerTreshold(l)", "$upperTreshold(u)" | sort) -join ' > ')
  if ($currentLevel -lt $lowerTreshold) { 'lower' } elseif ($upperTreshold -lt $currentLevel) { 'upper' } else { 'no' }
}

function evaluate {
  param(
    [bool]$force = $false,
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  if ($force) {
    write-log "evaluate force ==> trigger with $currentLevel%"
    return $currentLevel 
  }
  $activeLimit = get-violation -currentLevel $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
  write-log "$activeLimit limit has been exceeded"
  if (-not ('no' -eq $activeLimit)) {
    $lastTrigger = get-lastTrigger
    $lastLevel = $lastTrigger | get-level
    if ($lastLevel -gt 0) {
      $supposedDurationToGetIntoInnerTresholdRange = 30 # minutes
      $lastTriggerTime = get-lastTriggerTime
      $lastTriggerAssumedToBeInvalid = -not ((Get-Date) -gt $lastTriggerTime.AddMinutes($supposedDurationToGetIntoInnerTresholdRange))
      write-log "it is $(Get-Date -Format 'HH:mm'); last trigger: $lastTrigger --> $lastLevel% at $lastTriggerTime; validity treshold: $supposedDurationToGetIntoInnerTresholdRange ==> lastTriggerAssumedToBeInvalid: $lastTriggerAssumedToBeInvalid"
      if ($lastTriggerAssumedToBeInvalid) {
        return $currentLevel
      }
      if ($lastLevel -le $currentLevel -and $currentLevel -lt $lowerTreshold) {
        write-log "already triggered (on) and charging"
        return $null
      }
      if ($upperTreshold -lt $currentLevel -and $currentLevel -le $lastLevel) {
        write-log "already triggered (off) and depleting"
        return $null
      }
      else { "last trigger could not be found" }
      # todo: show an error if current level is further out than the last trigger
      write-log "trigger comparision allows to continue"
    }
    write-log "evaluation decides to trigger"
    return $currentLevel
  }
  write-log "evaluate ==> no trigger"
  return $null
}

function trigger-ifttt {
  param(
    [parameter(ValueFromPipeline)]
    $level
  )
  if ($null -ne $level) {
    write-log "triggering with $level%"
    place_a_trigger_file $level
    synchronise-trigger
    return $true
  }
  return $false
}

function launch {
  param(
    [bool]$force = $false,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  $currentLevel = get-batteryLevel
  write-log "current level is $currentLevel%"
  if (evaluate -force $force -currentLevel $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt) {
    compose-message -proc $currentLevel -force $force | show-notification
  }
}
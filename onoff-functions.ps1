. "$PSScriptRoot\logging.ps1"
. "$PSScriptRoot\battery.ps1"
. "$PSScriptRoot\trigger.ps1"

function get-violation {
  param(
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  write-log (("$currentLevel", "$lowerTreshold(l)", "$upperTreshold(u)" | sort) -join ' <= ')
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
  write-log "$activeLimit limit has been violated"
  if (-not ('no' -eq $activeLimit)) {
    $lastTrigger = get-lastTrigger
    $lastLevel = $lastTrigger | get-TriggerLevel
    if ($lastLevel -gt 0) {
      # check if the last trigger was reacting to the same situation
      # - it should not be too old
      $supposedDurationToGetIntoValidRange = 30 # minutes
      $lastTriggerTime = $lastTrigger | get-TriggerTime
      $lastTriggerIsTooOld = (Get-Date) -gt $lastTriggerTime.AddMinutes($supposedDurationToGetIntoValidRange)
      # - it should react to the same situation
      write-log "last trigger was placed due to $lastLevel% at $($lastTriggerTime.ToString('HH:mm'))"
      $lastViolation = get-violation -currentLevel $lastLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
      write-log "last trigger was due to $lastViolation limit violation $(if ($lastTriggerIsTooOld) {'but it is'} else {'and it is not'}) too old"
      $lastTriggerAssumedToBeInvalid = $lastViolation -ne $activeLimit -or $lastTriggerIsTooOld
      if ($lastTriggerAssumedToBeInvalid) {
        write-log "a new trigger must be set"
        return $currentLevel
      }
      # last trigger is still valid, check the progress made since last trigger
      #  <----- level is too low -------->  and <level is already increasing>
      if ($currentLevel -lt $lowerTreshold -and $lastLevel -lt $currentLevel) {
        write-log "already triggered (on) and charging"
        return $null
      }
      #   <---- level is too high ------->  and < level is already sinking >
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
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

function x {
  return [PSCustomObject]@{
    activeLimit = "lower"
    expectedChargerState = "loading"
    textWhenStatusError = ""
  }
}

function trigger-or-alarm {
  param(
    [int]$currentLevel,
    [string]$activeLimit,
    [string]$errorMessage
  )
  $lastTrigger = get-lastTrigger
  $lastLevel = $lastTrigger | get-TriggerLevel

  $supposedDurationToGetIntoValidRange = 30 # minutes

  $lastTriggerTime = $lastTrigger | get-TriggerTime
  $lastTriggerIsTooOld = (Get-Date) -gt $lastTriggerTime.AddMinutes($supposedDurationToGetIntoValidRange)
  write-log "last trigger was placed due to $lastLevel% at $($lastTriggerTime.ToString('HH:mm'))"
  $lastViolation = get-violation -currentLevel $lastLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
  $lastTriggerAssumedToBeInvalid = $lastViolation -ne $activeLimit -or $lastTriggerIsTooOld
  write-log "last trigger was due to $lastViolation limit violation $(if ($lastTriggerAssumedToBeInvalid) {'but it is already'} else {'and it is not yet'}) invalid"
  if ($lastTriggerAssumedToBeInvalid) {
    write-log "a new trigger must be set"
    return $currentLevel
  }
  show-notification $errorMessage
  return $null
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
  write-log "$activeLimit limit violation detected"
  if (-not ('no' -eq $activeLimit)) {
    $lastTrigger = get-lastTrigger
    $lastLevel = $lastTrigger | get-TriggerLevel
    if ($lastLevel -gt 0) {
      # find out the current charging status
      $isCharging = test-charging
      $isDepleting = -not $isCharging
      if ($activeLimit -eq 'lower') {
        if ($isCharging) {
          write-log "already charging"
          return $null
        }
        trigger-or-alarm `
          -currentLevel $currentLevel `
          -activeLimit $activeLimit `
          -errorMessage "based on the last trigger it should be already charging but the charger is off"
        }
      if ($activeLimit -eq 'upper') {
        if ($isDepleting) {
          write-log "already depleting"
          return $null
        }
        trigger-or-alarm `
          -currentLevel $currentLevel `
          -activeLimit $activeLimit `
          -errorMessage "based on the last trigger it should be already depleting but the charger is on"
      }
    }
    write-log "evaluation decides to trigger"
    return $currentLevel
  }
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
    synchronise-trigger $level
  }
}

function test-officeConnection {
  # in office we are connected to ethernet lan
  (get-netConnectionProfile | where { $_.InterfaceAlias -like 'ethernet' } | measure).Count -gt 0
}

function launch {
  param(
    [bool]$force = $false,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  $currentLevel = get-batteryLevel
  write-log "current level is $currentLevel%"
  if (test-officeConnection) {
    write-log "office connection detected"
    return $null
  }
  evaluate -force $force -currentLevel $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt
}
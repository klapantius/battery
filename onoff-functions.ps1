$triggerFolder = 'g:\My Drive\iktato\laptop';

function write-log {
  param(
    [string]$message
  )
  $logFile = "$triggerFolder\\log\\onoff.log"
  "$(Get-Date -Format 'yyMMdd HHmm') - $message" >> $logFile
}

function place_a_trigger_file {
  Remove-Item $triggerFolder\\*
  $fileName = "$triggerFolder\$(get-date -Format yyMMdd_HHmm)_$proc"
  write-log "place a trigger file: $fileName"
  "switch" | out-file $fileName
}

function get-lastTrigger {
  return Get-ChildItem -file $triggerFolder | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty FullName
}

function get-level {
  param(
    [parameter(ValueFromPipeline)]
    [string]$trigger
  )
  if ([string]::IsNullOrEmpty($trigger)) { return -1 }
  return [int]$($trigger -split '_' | Select-Object -Last 1)
}
function show-notification {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string]$message
  )
  return;
  # Add-Type -AssemblyName System.Windows.Forms 
  # $global:balloon = New-Object System.Windows.Forms.NotifyIcon
  # $path = (Get-Process -id $pid).Path
  # $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
  # $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info 
  # $balloon.BalloonTipText = $message
  # $balloon.BalloonTipTitle = "battery saver" 
  # $balloon.Visible = $true
  # $balloon.ShowBalloonTip(5000)
}

function get-batteryLevel {
  return Get-CimInstance Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
}

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

function compose-message {
  param(
    [int]$proc,
    [bool]$force = $false
  )
  $message = "charging will be toggled at $proc%"
  if ($force) { $message = "$message (manual)" }
  return $message
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
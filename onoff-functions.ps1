function write-log {
  param(
    [string]$message
  )
  "$(Get-Date -Format 'yyMMdd HHmm') - $message" | Out-File $env:temp\onoff.log -Append
}
function commit_a_change {
  $message = "$(Get-Date) - $proc%"
  $message | Out-File onoff.txt -Append
  git commit -am "$message"
  git push
}

$triggerFolder = 'g:\My Drive\iktato\laptop';
function place_a_trigger_file {
  Remove-Item $triggerFolder\\*
  "switch" | out-file "$triggerFolder\$(get-date -Format yyMMdd_HHmm)_$proc"
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
  Add-Type -AssemblyName System.Windows.Forms 
  $global:balloon = New-Object System.Windows.Forms.NotifyIcon
  $path = (Get-Process -id $pid).Path
  $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
  $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info 
  $balloon.BalloonTipText = $message
  $balloon.BalloonTipTitle = "battery saver" 
  $balloon.Visible = $true
  $balloon.ShowBalloonTip(5000)
}

function get-batteryLevel {
  return Get-WmiObject Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
}

function evaluate {
  param(
    [bool]$force = $false,
    [int]$proc,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  if ($force) { return $true }
  if (($proc -lt $lowerTreshold) -or ($upperTreshold -lt $proc)) { 
    $lastProc = get-lastTrigger | get-level
    if ($lastProc -ge 0) {
      if ($lastProc -le  $proc -and $proc -lt $lowerTreshold) {
        # todo: trigger again or show an error if current level is lower than the level of at last trigger
        # already triggered
        return $false
      }
      if ($upperTreshold -lt $proc -and $proc -le $lastProc) {
        # todo: trigger again or show an error if current level is lower than the level of at last trigger
        # already triggered
        return $false
      }
    }
    return $true
  }
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
  $message = "$proc -> switched"
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
  if (evaluate -force $force -proc $proc -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt) {
    compose-message -proc $proc -force $force | show-notification
  }
}
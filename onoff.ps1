[cmdletbinding()]
param(
  [switch]$force,
  [int]$lowerTreshold = 65, #22
  [int]$upperTreshold = 80 #82
)

function commit_a_change {
  $message = "$(Get-Date) - $proc%"
  $message | Out-File onoff.txt -Append
  git commit -am "$message"
  git push
}

function place_a_trigger_file {
  $path = 'g:\My Drive\iktato\laptop'
  del $path\\*
  "switch" | out-file "$path\$(get-date -Format yyMMdd_HHmm)_$proc"
}

function show-notification {
  [cmdletbinding()]
  param(
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

$proc = Get-WmiObject Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
$message = "$proc%"
if ($force -or ($proc -lt $lowerTreshold) -or ($upperTreshold -lt $proc)) {
  place_a_trigger_file
  $message = "$message ==> switched"
  if ($force) { $message = "$message (manual)" }
}
show-notification $message

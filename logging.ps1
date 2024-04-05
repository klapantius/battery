
function write-log {
    param(
        [string]$message
    )
    $logFile = "$triggerFolder\\log\\onoff.log"
    "$(Get-Date -Format 'yyMMdd HHmm') - $message" >> $logFile
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

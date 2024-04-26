
function write-log {
    param(
        [string]$message,
        [string]$loggingFolder = "$PSScriptRoot\\trigger"
    )
    if ($LogToConsole) { Write-Host $message }
    $logFile = "$loggingFolder\\onoff.log"
    "$(Get-Date -Format 'yyMMdd HHmm') - $message" | Out-File $logFile -Append -Encoding utf8
}

function show-notification {
    param(
        [string]$message
    )
    Add-Type -AssemblyName System.Windows.Forms 
    $global:balloon = New-Object System.Windows.Forms.NotifyIcon
    $path = (Get-Process -id $pid).Path
    $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
    $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $balloon.BalloonTipTitle = "Battery Manager Script"
    $balloon.BalloonTipText = $message
    $balloon.Visible = $true
    $balloon.ShowBalloonTip(5000)

    write-log $message
}

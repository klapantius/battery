function get-batteryLevel {
    return Get-CimInstance Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
}
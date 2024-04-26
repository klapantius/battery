function get-batteryStatus { Get-CimInstance Win32_Battery }

function get-batteryLevel { get-batteryStatus | select -ExpandProperty EstimatedChargeRemaining }

function test-charging { 2 -eq (get-batteryStatus | select -ExpandProperty BatteryStatus) }
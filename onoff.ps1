$lowerTreshold = 22
$upperTreshold = 82

$proc =  Get-WmiObject Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
if (($proc -lt $lowerTreshold) -or ($upperTreshold -lt $proc)) {
  $message = "$(Get-Date) - $proc%"
  $message | Out-File onoff.txt -Append
  git commit -am "$message"
  git push
}

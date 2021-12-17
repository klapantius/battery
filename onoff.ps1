function commit_a_change {
  $message = "$(Get-Date) - $proc%"
  $message | Out-File onoff.txt -Append
  git commit -am "$message"
  git push
}

function place_a_trigger_file {
  $path='g:\My Drive\iktato\laptop'
  del $path\\*
  "switch" | out-file "$path\$(get-date -Format yyMMdd_HHmm)_$proc"
}

$lowerTreshold = 65 #22
$upperTreshold = 70 #82

$proc =  Get-WmiObject Win32_Battery | select -ExpandProperty EstimatedChargeRemaining
if (($proc -lt $lowerTreshold) -or ($upperTreshold -lt $proc)) {
  place_a_trigger_file
}

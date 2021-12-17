#Get-Date | Out-File onoff.txt
#git commit -am "switch"
#git push

$path='g:\My Drive\iktato\laptop'
"x" | out-file "$path\$(get-date -Format yyMMdd_HHmm)_manual"


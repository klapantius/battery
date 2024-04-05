function place_a_trigger_file {
    Remove-Item $triggerFolder\\*
    $fileName = "$triggerFolder\$(get-date -Format yyMMdd_HHmm)_$proc"
    write-log "place a trigger file: $fileName"
    "switch" | out-file $fileName
}

function get-lastTrigger {
    $result = Get-ChildItem -file $triggerFolder | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty FullName
    # Write-Host "get-lastTrigger returns '$result'"
    return $result
}

function get-level {
    param(
        [parameter(ValueFromPipeline)]
        [string]$trigger
    )
    if ([string]::IsNullOrEmpty($trigger)) { return -1 }
    return [int]$($trigger -split '_' | Select-Object -Last 1)
}

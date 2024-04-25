$triggerFolder = Join-Path -Path $PSScriptRoot -ChildPath 'trigger';

function place_a_trigger_file {
    $fileName = "$triggerFolder\$(get-date -Format yyMMdd_HHmm)_$proc"
    write-log "place a trigger file: $fileName"
    "switch" | out-file $fileName
    # remove older triggers
    $recently = (Get-Date).AddHours(-1)
    dir $triggerFolder -File | where { $_.CreationTime -lt $recently } | foreach { del $_ -ErrorAction SilentlyContinue }
}

function synchronise-trigger {
    if (-not ( Test-Path (Join-Path $PSScriptRoot '.git'))) { return }
    try {
        write-log "synchronizing git repository"
        pushd $triggerFolder
        git add .
        git commit -m "sync $(Get-Date -Format yyMMdd_HHmm)"
        git pull
        git push
    }
    finally {
        popd
    }
}

function get-lastTrigger {
    $result = Get-ChildItem -file $triggerFolder | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty Name
    return $result
}

function get-lastTriggerTime {
    $result = Get-ChildItem -file $triggerFolder | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty CreationTime
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

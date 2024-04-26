$triggerFolder = Join-Path -Path $PSScriptRoot -ChildPath 'trigger';

function place_a_trigger_file {
    param(
        $triggeringLevel
    )
    $fileName = "$triggerFolder\trigger_$(get-date -Format yyMMdd_HHmm)_$triggeringLevel"
    $year
    write-log "place a trigger file: $fileName"
    "switch" | out-file $fileName
    # remove triggers older than a certain time
    $recently = (Get-Date).AddHours(-1)
    dir $triggerFolder -File trigger_* | where { $_.CreationTime -lt $recently } | foreach { del $_ -ErrorAction SilentlyContinue }
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
    $result = dir $triggerFolder -file trigger_* | Sort-Object -Descending CreationTime | Select-Object -First 1
    return $result
}

function get-TriggerName {
    param(
        [parameter(ValueFromPipeline)]
        $triggerFile
    )
    return (get-item $triggerFile | select -ExpandProperty Name)
}
function get-TriggerTime {
    param(
        [parameter(ValueFromPipeline)]
        $triggerFile
    )
    return (get-item $triggerFile | select -ExpandProperty CreationTime)
}

function get-TriggerLevel {
    param(
        [parameter(ValueFromPipeline)]
        [string]$triggerFile
    )
    if ($null -eq $triggerFile) { return -1 }
    $fileName = $triggerFile | get-TriggerName
    return [int]$($fileName -split '_' | Select-Object -Last 1)
}

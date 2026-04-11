$entry = Get-ChildItem src\*.cbl | ForEach-Object {
    $c = Get-Content $_ -Raw
    if ($c -match '\*>\s*MAIN' -and $c -match '(?i)program-id\.\s+(\S+)\.') {
        $matches[1]
    }
} | Select-Object -First 1

if ($entry) {
    $proj = Get-Content Processor.cblproj -Raw
    $proj = $proj -replace '<StartupObject>[^<]*</StartupObject>', "<StartupObject>$entry</StartupObject>"
    Set-Content Processor.cblproj $proj -Encoding UTF8
    Write-Host "StartupObject -> $entry"
} else {
    Write-Warning "Ningun .cbl tiene el marcador '*> MAIN'"
}

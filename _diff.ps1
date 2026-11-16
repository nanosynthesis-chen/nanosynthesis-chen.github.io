Add-Type -AssemblyName System.IO.Compression.FileSystem

$xlsx = "C:\Users\suhuai\Desktop\nanosynthesis-site\papers.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($xlsx)

$ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
$ssReader = New-Object System.IO.StreamReader($ssEntry.Open())
[xml]$ssXml = $ssReader.ReadToEnd(); $ssReader.Close()
$shared = @()
foreach ($si in $ssXml.sst.si) {
    if ($si.t) { $shared += [string]$si.t }
    elseif ($si.r) { $txt = ""; foreach ($r in $si.r) { $txt += [string]$r.t }; $shared += $txt }
    else { $shared += "" }
}

$sheetEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")
$shReader = New-Object System.IO.StreamReader($sheetEntry.Open())
[xml]$shXml = $shReader.ReadToEnd(); $shReader.Close()

function CellVal($c) {
    if (-not $c) { return "" }
    $t = $c.t
    $v = $c.v
    if ($t -eq "s") { return $shared[[int]$v] }
    if ($v) { return [string]$v }
    if ($c.is -and $c.is.t) { return [string]$c.is.t }
    return ""
}

$rows = $shXml.worksheet.sheetData.row

Write-Host "=============================================="
Write-Host "  EXCEL 2026 年论文（编号从新到旧）"
Write-Host "=============================================="

foreach ($r in $rows) {
    $seq = ""; $title = ""; $year = ""; $doi = ""; $auth = ""; $journal = ""
    foreach ($c in $r.c) {
        $col = $c.r -replace '\d',''
        $val = CellVal $c
        if ($col -eq "A") { $seq = $val }
        if ($col -eq "B") { $title = $val }
        if ($col -eq "C") { $auth = $val }
        if ($col -eq "D") { $journal = $val }
        if ($col -eq "E") { $year = $val }
        if ($col -eq "F") { $doi = $val }
    }
    if ($seq -match '^\d+$' -and [int]$seq -ge 200 -and [int]$seq -le 215) {
        $shortTitle = if ($title.Length -gt 65) { $title.Substring(0,65) + "..." } else { $title }
        Write-Host "#$seq | $year | $journal"
        Write-Host "      $shortTitle"
        Write-Host "      DOI: $doi"
        Write-Host ""
    }
}

$zip.Dispose()
